
#!/bin/bash

#Скрипт архивирует указанные директории, шифрует AES-ом и закидывает на Dropbox.
 
TARGETS="/boot /etc /root"
mount /boot
 
for i in $TARGETS; do
filename=$(echo $i | sed 's/\//-/g'); #убираем / в имени файла
tar -czPf /var/archives/`echo $HOSTNAME`$filename-`date +%Y%m%d`.tar.gz $i; # e.g. gbox-etc-20100314.tar.gz
done
 
for i in `ls /var/archives/`; do
gpg -e --symmetric --cipher-algo AES --batch --passphrase «Your_Password» /var/archives/$i; # шифруем
mv /var/archives/$i.gpg /home/allein/Dropbox/archives/; # шифрованные файлы закидуем на Dropbox
rm -f /var/archives/$i; # остальное удаляем
done
 
umount /boot