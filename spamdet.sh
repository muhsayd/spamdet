for message in `/usr/sbin/exiqgrep -i`; 
do 
	PHPSendingDomain=`/usr/sbin/exim -Mvh ${message} | egrep 'X-PHP-Script' | awk -F"X-PHP-Script: " '{print $2}' | awk -F"/" '{print $1}'`
        PHPSendingScript=`/usr/sbin/exim -Mvh ${message} | egrep 'X-PHP-Script' | awk -F"X-PHP-Script: " '{print $2}' | cut -d"/" -f2- | awk -F" for" '{print $1}'`
	spamflag=`/usr/sbin/exim -Mvh ${message} | egrep 'X-Spam-Flag' | awk '{print $NF}'`
        spamscore=`/usr/sbin/exim -Mvh ${message} | egrep 'X-Spam-Score' | awk '{print $NF}'`
done
# | sort | uniq -c | sort -n



