#!/bin/bash
 
# Скрипт резервного копирования системы
 
# Автор: Захаров Сергей Васильевич
# e-mail: sv(собака)sadmin.pp.ua
# icq: 222212387
# Сайт: http://www.sadmin.pp.ua
# Дата модификации файла: 2011-09-25

#---------------------Предварительная подготовка-------------------------------------
#Для начала создаем системного пользователя на машине куда будем копировать бекап:
#useradd -d /srv/backup backup_user
#
#Создаем пользователя для бекапирования баз mysql на локальном сервере:
#GRANT SELECT,LOCK TABLES ON *.* TO backup_user@localhost IDENTIFIED BY 'PASSWD';
#
#Создаем сертификат для беспарольного доступа:
#ssh-keygen -t rsa -b 4091
#
#Копируем публичный ключ на удаленный сервер
#ssh-copy-id -i $HOME/.ssh/id_rsa.pub backup_server
#
#Или переносим вручную из файла id_rsa.pub в файл на удаленном сервере authorized_keys.
#Это может потребоваться если ssh работает на нестандартном порту. Дело в том, что утилита ssh-copy-id не поддерживает копирование на нестандатном порту ssh.
#
#Пробуем зайти:
#ssh backup_server
#------------------------------------------------------------------------------------
 
# имя компьютера
COMP=ns
# имя и расположение tar
TAR=/bin/tar
 
SCRIPT_DIR="/srv/backup"
 
# Что бекапим
DIR_SOURCE="/boot \
/etc \
/root \
/usr/local \
/usr/share/phpmyadmin \
/usr/share/postfixadmin \
/usr/share/smbind \
/var/cache/bind \
/var/cache/munin \
/var/log \
/var/www"
 
# Лог
LOG="/srv/backup/archive_$COMP.log"
ERRORLOG="/srv/backup/archive_error_$COMP.log"
 
# e-mail для уведомлений
MAIL='admin@examole.com'
 
# Где храним бекапы
DIR_TARGET="/srv/backup/$COMP"
 
EXIT_ERROR ()
{
    echo "$(date +%F_%R:%S) ################## End script ERROR ##################" >> $LOG
    echo "" >> $LOG
    exit 1
}
 
echo "$(date +%F_%R:%S) #################### Start script ####################" >> $LOG
echo "$(date +%F_%R:%S) Начало архивации" >> $LOG
 
# Информация которая может пригодится при восстановлении
fdisk -l > $DIR_TARGET/fdisk.bak 2> /dev/null
dmidecode > $DIR_TARGET/dmidecode.bak 2> /dev/null
cat /etc/fstab > $DIR_TARGET/fstab.bak 2> /dev/null
dmesg > $DIR_TARGET/dmesg.bak 2> /dev/null
lspci > $DIR_TARGET/lspci.bak 2> /dev/null
# debian
dpkg -l > $DIR_TARGET/dpkg.bak 2> /dev/null
# centos
# rpm -qa > $DIR_TARGET/rpm.bak 2> /dev/null
 
# Если используем LVM
#pvdisplay > $DIR_TARGET/pvdisplay.bak 2> /dev/null
#vgdisplay > $DIR_TARGET/vgdisplay.bak 2> /dev/null
#vdisplay > $DIR_TARGET/lvdisplay.bak 2> /dev/null
 
 
############################ mysql #############################
echo "$(date +%F_%R:%S) Дамп всех бд mysql" >> $LOG
 
# Тут необходимо не забыть прописать бекапного юзера и пароль для доступа к mysql
/usr/bin/mysql --user=backup_user --password=PASSWD -e 'show databases;' | egrep -v '^Database|^information_schema' | \
    awk '{system ("/usr/bin/mysqldump --add-drop-database --opt --user=backup_user "$1" --password=\"PASSWD\" > /srv/backup/ns/"$1".sql")}'
 
######################### files ################################
 
cp $SCRIPT_DIR/{*.sh,*.log} $DIR_TARGET
 
### Создаем архив
if $TAR -cpf $DIR_TARGET/full-$(date +%F_%H-%M).tar.gz $DIR_SOURCE $DIR_TARGET/{*.bak,*.sql,*.sh,*.log} 2>> $ERRORLOG
    then
	echo "$(date +%F_%R:%S) Архивация прошла успешно" >> $LOG
	# echo "$COMP: Архивация прошла успешно" |mail -s "$COMP: Архивация прошла успешно" $MAIL
    else
	echo "$(date +%F_%R:%S) При архивации произошла ОШИБКА" >> $LOG
	echo "$COMP :При архивации произошла ОШИБКА" |mail -s "$COMP: При архивации произошла ОШИБКА" $MAIL
	EXIT_ERROR
fi
 
# Удаляем временные файлы
rm -f $DIR_TARGET/{*.sh,*.log,*.sql,*.bak}
 
### Копируем архив на удаленный сервер
FILE_ARCHIVE=`ls -w1 /srv/backup/ns |tail -n1`
echo "$(date +%F_%R:%S) Копирование архива $FILE_ARCHIVE на удаленный сервер" >> $LOG
if scp -P 2222 -i /srv/backup/.ssh/id_rsa $DIR_TARGET/$FILE_ARCHIVE backup_user@backup_server:/srv/backup/$COMP
    then
	echo "$(date +%F_%R:%S) Архив $FILE_ARCHIVE успешно скопирован на удаленный-сервер" >> $LOG
	# echo "$COMP: Архив $FILE_ARCHIVE успешно скопирован на удаленный-сервер" |mail -s "$COMP: Архив $FILE_ARCHIVE успешно скопирован на удаленный-сервер" $MAIL
    else
	echo "$(date +%F_%R:%S) При копировании на удаленный сервер произошла ОШИБКА" >> $LOG
	echo "$COMP: При копировании архива $FILE_ARCHIVE на удаленный сервер произошла ОШИБКА" |mail -s "$COMP: При копировании архива $FILE_ARCHIVE на удаленный сервер произошла ОШИБКА" $MAIL
	EXIT_ERROR
fi
 
# Проверяем есть ли файлы для удаления на удаленном сервере старше двух месяцев
FILE_COUNT=`ssh -p 2222 -i /srv/backup/.ssh/id_rsa backup_user@backup_server "find ./ns -type f -ctime +62 -name "*.gz" |wc -l"`
echo "$(date +%F_%R:%S) FILE_COUNT = $FILE_COUNT" >> $LOG
# echo "$COMP: FILE_COUNT = $FILE_COUNT (на удаленном сервере)" |mail -s "$COMP: FILE_COUNT = $FILE_COUNT (на удаленном сервере)" $MAIL
 
# Проверяем есть ли файлы на удаление (-gt - больше нуля)
if [ $FILE_COUNT -gt "0" ]
    then
    #Удаляем файлы двухмесячной давности
    if ssh -p 2222 -i /srv/backup/.ssh/id_rsa backup_user@backup_server "find ./ns -type f -ctime +62 -name "*.gz" -exec rm {} \;"
	then
	    echo "$(date +%F_%R:%S) Устаревшие архивы размещенные на удаленном сервере успешно удалены" >> $LOG
	    # echo "$COMP: старевшие архивы размещенные на удаленном сервере успешно удалены" |mail -s "$COMP: Устаревшие архивы размещенные на удаленном сервере успешно удалены" $MAIL
        else
    	    echo "$(date +%F_%R:%S) При удалении устаевших архивов размещенных на удаленном сервере  произошла ОШИБКА" >> $LOG
	    echo "$COMP: При удалении устаевших архивов размещенных на удаленном сервере  произошла ОШИБКА" |mail -s "$COMP: При удалении устаевших архивов размещенных на удаленном сервере  произошла ОШИБКА" $MAIL
	    EXIT_ERROR
    fi
fi
 
 
if rm -f $DIR_TARGET/$FILE_ARCHIVE
    then
	echo "$(date +%F_%R:%S) Файл $FILE_ARCHIVE успешно удален на локальном сервере" >> $LOG
	# echo "$COMP: Файл $FILE_ARCHIVE успешно удален на локальном сервере" |mail -s "$COMP: Файл архива успешно удален на локальном сервере" $MAIL
    else
	echo "$(date +%F_%R:%S) При удалении $FILE_ARCHIVE на локальном сервере возникла ОШИБКА" >> $LOG
	echo "$COMP: При удалении $FILE_ARCHIVE на локальном сервере возникла ОШИБКА" |mail -s "$COMP: При удалении архива на локальном сервере возникла ОШИБКА" $MAIL
	EXIT_ERROR
fi
 
echo "$(date +%F_%R:%S) ##################### End script #####################" >> $LOG
echo "" >> $LOG