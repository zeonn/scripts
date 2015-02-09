#принимаем имя проекта, в качестве первого аргумента к скрипту
NAME_OF_PROJECT=$1

#добавляем правила в конфигурационый файл апача
add_to_apache_conf="server {
listen 80;
server_name ${NAME_OF_PROJECT} www.${NAME_OF_PROJECT};
access_log /var/log/www/${NAME_OF_PROJECT}/nginx_access.log;
error_log /var/log/www/${NAME_OF_PROJECT}/nginx_error.log;

location ~ /\.ht {
deny all;
}

location / {
proxy_pass http://192.168.11.8:8080/;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-for \$remote_addr;
proxy_set_header Host \$host;
proxy_connect_timeout 60;
proxy_send_timeout 90;
proxy_read_timeout 90;
proxy_redirect off;
proxy_set_header Connection close;
proxy_pass_header Content-Type;
proxy_pass_header Content-Disposition;
proxy_pass_header Content-Length;
}
}"

#создаем каталог для логов
mkdir /var/log/www/${NAME_OF_PROJECT}

#добовляем новый хост
touch /etc/nginx/sites-available/${NAME_OF_PROJECT}
echo "$add_to_apache_conf" >> /etc/nginx/sites-available/${NAME_OF_PROJECT}

#включаем сайт
ln -s /etc/nginx/sites-available/${NAME_OF_PROJECT} /etc/nginx/sites-enabled/

#перезапускаем nginx
service nginx restart
