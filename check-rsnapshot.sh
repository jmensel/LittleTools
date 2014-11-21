#!/bin/bash

# jmensel@gmail.com
# Checks the rsnapshot backup log for success on the daily job for today's date, and fusses if there's not a success message
# sends email to whomever's listed.  One address only. It's using mailx, so just send it to a list and keep it simple.

RECIPIENT='alerts@yourdomain.com'

DSTAMP=$(date +%d/%b/%Y)

RESULT=$(grep -e $DSTAMP /var/log/rsnapshot | grep -e 'rsnapshot daily: completed successfully' | head -n 1)

log=$(printf "The Rsnapshot Job on backup01 failed.  You should look into it.  Logfile follows.\n\n" > /tmp/rsnapshot.fail; tail -n 25 /var/log/rsnapshot >> /tmp/rsnapshot.fail)

if [ -z "$RESULT" ]
 then
    echo "[failure] - Daily Rsnapshot job failed on backup01.yourdomain.com"

    cat /tmp/rsnapshot.fail | mail -s  "[failure] - Daily Rsnapshot job failed on backup01.yourdomain.com" $RECIPIENT

fi

rm /tmp/rsnapshot.fail