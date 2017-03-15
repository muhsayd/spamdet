#!/bin/bash

if [ -f "/root/spammingdomains.txt" ]
then
	> /root/spammingdomains.txt;
else
	touch /root/spammingdomains.txt;
fi
if [ -f "/root/spammingscripts.txt" ]
then
        > /root/spammingscripts.txt;
else
        touch /root/spammingscripts.txt;
fi
for message in `/usr/sbin/exiqgrep -i`; 
do 
	PHPSendingDomain=`/usr/sbin/exim -Mvh ${message} | egrep 'X-PHP-Script' | awk -F"X-PHP-Script: " '{print $2}' | awk -F"/" '{print $1}'`
        PHPSendingScript=`/usr/sbin/exim -Mvh ${message} | egrep 'X-PHP-Script' | awk -F"X-PHP-Script: " '{print $2}' | cut -d"/" -f2- | awk -F" for" '{print $1}'`
	spamflag=`/usr/sbin/exim -Mvh ${message} | egrep 'X-Spam-Flag' | awk '{print $NF}'`
        spamscore=`/usr/sbin/exim -Mvh ${message} | egrep 'X-Spam-Score' | awk '{print $NF}'`
	sender=`/usr/sbin/exim -Mvh ${message} | egrep ' From: ' | awk -F"From:" '{print $NF}' | awk -F"<" '{print $NF}' | awk -F">" '{print $1}'`
	subject=`/usr/sbin/exim -Mvh ${message} | egrep 'Subject:' | awk -F": " '{print $NF}' | sed 's/=//g'`
	if `grep -q ${sender} /root/senders.txt`
	then
		senderscore=`grep ${sender} /root/senders.txt | awk -F"=" '{print $NF}'`
		senderscore=$((${senderscore} + 1))
		if [ `echo ${sender} | grep -i -q 'wordpress'` ]
		then
			/usr/sbin/exim -Mrm ${message}
		fi
	else
		echo "${sender}=1" >> /root/senders.txt
                if [ `echo ${sender} | grep -i -q 'wordpress'` ]
                then
                        /usr/sbin/exim -Mrm ${message}
                fi
	fi
	if [ `/usr/sbin/exim -Mvh ${message} | head -3 | tail -1` = '<>' ]
	then
		bouncemail=`/usr/sbin/exim -Mvh ${message} | grep 'To: ' | awk -F"To: " '{print $2}'` 
		if `grep -q ${bouncemail} /root/bouncingmails.txt`
		then
			bouncingscore=`grep ${bouncemail} /root/bouncingmails.txt | awk -F"=" '{print $NF}'`
			bouncingscore=$((${bouncingscore} + 1))
			sed -i -r "/$bouncemail/s/=.*$/=$bouncingscore/" /root/bouncingmails.txt
			/usr/sbin/exim -Mrm ${message}
		else
			echo "${bouncemail}=1" >> /root/bouncingmails.txt
			/usr/sbin/exim -Mrm ${message}
		fi
	fi
	if [ ! -z "$PHPSendingDomain" ]
	then
		if `grep -q ${PHPSendingDomain} /root/spammingdomains.txt`
		then
			domainspamscore=`grep ${PHPSendingDomain} /root/spammingdomains.txt | cut -d'=' -f2`
			echo ${PHPSendingDomain}: ${domainspamscore}
			domainspamscore=$((${domainspamscore} + 1));
			echo -e "Increment domainspamscore:\n\t ${PHPSendingDomain}: ${domainspamscore}"
			sed -i -r "/$PHPSendingDomain/s/=.*$/=$domainspamscore/" /root/spammingdomains.txt
			if `grep -q ${PHPSendingScript} /root/spammingscripts.txt`
			then
				scriptspamscore=`grep "${PHPSendingDomain}" /root/spammingscripts.txt | grep "${PHPSendingScript}" | cut -d'=' -f2`
				scriptspamscore=$((${scriptspamscore} + 1));
				sed -i -r "/$PHPSendingDomain/{;/$PHPSendingScript/s/=.*$/=$scriptspamscore/;}" /root/spammingscripts.txt
			fi
		else
			echo "${PHPSendingDomain}=1" >> /root/spammingdomains.txt
			echo "${PHPSendingDomain}/${PHPSendingScript}=1" >> /root/spammingscripts.txt
		fi
	fi
	if [ "$spamflag" = 'YES' ] && [ "$spamscore" -gt 50 ]
	then
		echo -e "Message ID: ${message}"
		echo -e "Php Sending Script: ${PHPSendingDomain}/${PHPSendingScript}"
		echo -e "Spam Flag: ${spamflag}"
		echo -e "Spam Score: ${spamscore}"
		/usr/sbin/exim -Mrm ${message}
	else
		echo -e "Message: ${message} --> [ OK ]"
	fi
done
# | sort | uniq -c | sort -n



