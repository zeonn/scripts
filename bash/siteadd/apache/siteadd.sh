#!/bin/bash

echo -e "Введите название проекта (Например example.com):";
read NAME_OF_PROJECT

#создадим пользователя, от имени которого будет работать сайт
USER_NAME=$NAME_OF_PROJECT
useradd ${USER_NAME} -b /sites/ -m -U -s /bin/false

#создаем папки проекта
mkdir /sites/${NAME_OF_PROJECT}
mkdir /sites/${NAME_OF_PROJECT}/www/
mkdir /sites/${NAME_OF_PROJECT}/tmp/
mkdir /sites/${NAME_OF_PROJECT}/logs/

#указываем владельца и права на папки
chown -R ${USER_NAME}:${USER_NAME} /sites/${NAME_OF_PROJECT}/
chmod -R 775 /sites/${NAME_OF_PROJECT}/
chown -R ${USER_NAME}:${USER_NAME} /sites/${NAME_OF_PROJECT}/*
chmod -R 775 /sites/${NAME_OF_PROJECT}/*

#Т.к. у нас web-сервер работает от пользователя www-data,
#то он не сможет получить доступ к содержимому домашней директории пользователя,
#но при создании была создана одноименная группа, в нее нам необходимо добавить пользователя www-data.
usermod -a -G ${USER_NAME} www-data

# Создаем страничку в www для того чтобы сайт хоть что-то отражал
touch /sites/${NAME_OF_PROJECT}/www/index.html
echo "Coming soon... ${NAME_OF_PROJECT}" >> /sites/${NAME_OF_PROJECT}/www/index.html
chown ${USER_NAME}:${USER_NAME} /sites/${NAME_OF_PROJECT}/www/index.html

#добавляем правила в конфигурационый файл апача
add_to_apache_conf="<VirtualHost *:8080>
        DocumentRoot /sites/${NAME_OF_PROJECT}/www
        ServerAdmin admin@${NAME_OF_PROJECT}
        ServerName ${NAME_OF_PROJECT}
        ServerAlias www.${NAME_OF_PROJECT}
        ErrorLog /sites/${NAME_OF_PROJECT}/logs/apache_error.log
        CustomLog /sites/${NAME_OF_PROJECT}/logs/apache_access.log combined
<Directory />

AssignUserId www-data ${USER_NAME}

php_admin_value open_basedir "/sites/${NAME_OF_PROJECT}/:."
php_admin_value upload_tmp_dir "/sites/${NAME_OF_PROJECT}/tmp"
php_admin_value session.save_path "/sites/${NAME_OF_PROJECT}/tmp"
</VirtualHost>"

#добовляем новый хост
touch /etc/apache2/sites-available/${NAME_OF_PROJECT}
echo "$add_to_apache_conf" >> /etc/apache2/sites-available/${NAME_OF_PROJECT}

#включаем конфигурацию сайта
a2ensite ${NAME_OF_PROJECT}
echo "** "
echo "** Ваш сайт нужно разместить в каталог: /sites/${NAME_OF_PROJECT}/www "
echo "** "

#Создаем БД
echo -e "Создать базу данных для проекта?(yes/no)";
read CREATE_DB

if  [ "$CREATE_DB" = "yes" -o "$CREATE_DB" = "y" -o "$CREATE_BAZA" = "YES" ]; then
        echo -e "Введите имя базы данных:";
        read DB_NAME
        echo -e "Введите имя пользователя для базы ${DB_NAME}, который будет обладать всем правами:";
        read DB_USER_NAME
        echo -e "Введите пароль для пользователя ${DB_USER_NAME}:";
        read -s DB_PASS
        # Создаем базу данных имя которой мы ввели
        echo -e "Теперь будет необходимо ввести 2 раза пароль root MySQL, если пароля нет, просто нажмите Enter";
        mysql -uroot -p --execute="CREATE DATABASE $DB_NAME;"
        # Создаем нового пользователя
        mysql -uroot -p --execute="GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER_NAME}'@'localhost' IDENTIFIE$

        echo -e "База данных $DB_NAME создана.";

else
     echo -e "База данных не была создана";
fi

echo "Перезапускаем apache..."
/etc/init.d/apache2 restart

echo -e "Локальный сайт $NAME_OF_PROJECT готов к работе.";

echo "***********************************"
echo "Создана новая база MySql с еменем: ${DB_NAME}"
echo "К этой базе нужно конектится под юзером: ${DB_USER_NAME}"
