#!/bin/bash

echo -e "Введите название проекта (Например example.com):";
read NAME_OF_PROJECT

#создадим пользователя, от имени которого будет работать сайт
USER_NAME=$NAME_OF_PROJECT
useradd ${USER_NAME} -b /var/www/ -m -U -s /bin/false
#usermod -u 999 ${USER_NAME}   #скрыть пользователя с экрана приветствия ubuntu

#создаем папки проекта
mkdir /var/www/${NAME_OF_PROJECT}
mkdir /var/www/${NAME_OF_PROJECT}/www/
mkdir /var/www/${NAME_OF_PROJECT}/tmp/
mkdir /var/www/${NAME_OF_PROJECT}/logs/

#указываем владельца и права на папки
chown -R ${USER_NAME}:${USER_NAME} /var/www/${NAME_OF_PROJECT}/
chmod -R 775 /var/www/${NAME_OF_PROJECT}/
chown -R ${USER_NAME}:${USER_NAME} /var/www/${NAME_OF_PROJECT}/*
chmod -R 775 /var/www/${NAME_OF_PROJECT}/*

#Т.к. у нас web-сервер работает от пользователя www-data,
#то он не сможет получить доступ к содержимому домашней директории пользователя,
#но при создании была создана одноименная группа, в нее нам необходимо добавить пользователя www-data.
usermod -a -G ${USER_NAME} www-data

#удалить лишние файлы
cd /var/www/${NAME_OF_PROJECT}
find -maxdepth 1 -type f -exec rm {} \;

# Создаем страничку в www для того чтобы сайт хоть что-то отражал
touch /var/www/${NAME_OF_PROJECT}/www/index.html
echo "Coming soon... ${NAME_OF_PROJECT}" >> /var/www/${NAME_OF_PROJECT}/www/index.html
chown ${USER_NAME}:${USER_NAME} /var/www/${NAME_OF_PROJECT}/www/index.html

#добавляем правила в конфигурационый файл апача
add_to_apache_conf="<VirtualHost *:81>
    DocumentRoot /var/www/${NAME_OF_PROJECT}/www
    ServerAdmin admin@${NAME_OF_PROJECT}
    ServerName ${NAME_OF_PROJECT}
    ServerAlias www.${NAME_OF_PROJECT}
    ErrorLog /var/www/${NAME_OF_PROJECT}/logs/apache_error.log
    CustomLog /var/www/${NAME_OF_PROJECT}/logs/apache_access.log combined

    <Directory />
        Options -ExecCGI -Indexes -Includes +FollowSymLinks
        AllowOverride All
        <Limit GET POST>
            Order allow,deny
            Allow from all
        </Limit>
        <LimitExcept GET POST>
            Order deny,allow
            Deny from all
        </LimitExcept>
    </Directory>

    ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
    <Directory "/usr/lib/cgi-bin">
        AllowOverride All
        Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
        Order allow,deny
        Allow from all
    </Directory>

    Alias /doc/ "/usr/share/doc/"
    <Directory "/usr/share/doc/">
        Options Indexes MultiViews FollowSymLinks
        AllowOverride all
        Order deny,allow
        Deny from all
        Allow from 127.0.0.0/255.0.0.0 ::1/128
    </Directory>

    AssignUserId www-data ${USER_NAME}
    
    php_admin_value open_basedir "/var/www/${NAME_OF_PROJECT}/:."
    php_admin_value upload_tmp_dir "/var/www/${NAME_OF_PROJECT}/tmp"
    php_admin_value session.save_path "/var/www/${NAME_OF_PROJECT}/tmp"

</VirtualHost>"

#добовляем новый хост
touch /etc/apache2/sites-available/${NAME_OF_PROJECT}
echo "$add_to_apache_conf" >> /etc/apache2/sites-available/${NAME_OF_PROJECT}

#включаем конфигурацию сайта
a2ensite ${NAME_OF_PROJECT}
service apache2 reload

echo "** "
echo "** Ваш сайт нужно разместить в каталог: /var/www/${NAME_OF_PROJECT}/www "
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
        mysql -uroot -p --execute="GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER_NAME}'@'localhost' IDENTIFIED BY '${DB_PASS}';"

        echo -e "База данных $DB_NAME создана.";

else
     echo -e "База данных не была создана";
fi

echo "Перезапускаем apache..."
/etc/init.d/apache2 restart


#сиздаем виртуальный хост nginx

add_to_nginx_conf="server {
listen 80;
server_name ${NAME_OF_PROJECT} www.${NAME_OF_PROJECT};
access_log /var/www/${NAME_OF_PROJECT}/logs/nginx_access.log;
error_log /var/www/${NAME_OF_PROJECT}/logs/nginx_error.log;

location ~* \.(jpg|jpeg|gif|png|css|zip|tgz|gz|rar|bz2|doc|xls|exe|pdf|ppt|tar|wav|bmp|rtf|swf|ico|flv|txt|docx|xlsx)$ {
root /var/www/${NAME_OF_PROJECT}/www/;
index index.html index.php;
access_log off;
expires 30d;
}
location ~ /\.ht {
deny all;
}

location / {
proxy_pass http://127.0.0.1:81/;
include /etc/nginx/proxy.conf;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-for \$remote_addr;
proxy_set_header Host \$host;
proxy_redirect off;
proxy_set_header Connection close;
proxy_pass_header Content-Type;
proxy_pass_header Content-Disposition;
proxy_pass_header Content-Length;
}
}"

#добовляем новый хост
touch /etc/nginx/sites-available/${NAME_OF_PROJECT}
echo "$add_to_nginx_conf" >> /etc/nginx/sites-available/${NAME_OF_PROJECT}

#включаем сайт
ln -s /etc/nginx/sites-available/${NAME_OF_PROJECT} /etc/nginx/sites-enabled/

#перезапускаем nginx
service nginx restart


echo -e "Локальный сайт $NAME_OF_PROJECT готов к работе.";

echo "***********************************"
echo "Создана новая база MySql с еменем: ${DB_NAME}"
echo "К этой базе нужно конектится под юзером: ${DB_USER_NAME}"
