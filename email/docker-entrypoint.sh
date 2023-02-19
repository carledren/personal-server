#!/bin/bash 

# move it to be able to chmod it. k8s secret is read only fs
cp /etc/fetchmail/fetchmailrc /home/erebe/
chmod 600 /home/erebe/fetchmailrc

chown -R erebe:erebe /data
mkdir /data/mail-tmp

mail_filter_url=$(curl -s https://api.github.com/repos/erebe/hmailfilter/releases/latest | grep browser_download_url | cut -d '"' -f 4)
curl -L -o hmailclassifier $mail_filter_url
chmod +x hmailclassifier

/usr/bin/rspamd -c /etc/rspamd/rspamd.conf -f -i &
dovecot -F &
vsmtp -c /etc/vsmtp/vsmtp.vsl --no-daemon --stdout &

while true 
do 
  for email in $(find /data/mail-tmp -name '*.eml')
  do
    echo "Moving email $email"
    folder=$(cat $email | ./hmailclassifier | sed -E 's#^\.([^/]+)/$#\1#')
    doveadm mailbox create -u erebe $folder 2> /dev/null
    cat $email | /usr/lib/dovecot/dovecot-lda -d erebe -m INBOX
    cat $email | /usr/lib/dovecot/dovecot-lda -d erebe -m "$folder"

    rm $email


  done

  sleep 1
done

