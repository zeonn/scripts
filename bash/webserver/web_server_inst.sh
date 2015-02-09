# каталог в котором лежит скрипт
ROOT_PATH=$(cd $(dirname $0) && pwd);

#узнаем свой внешний IP
EXT_IP=$(dig +short myip.opendns.com @resolver1.opendns.com);


# Обновляемся
apt-get update -y
# ставим apache2 и его зависимости.
apt-get install apache2-mpm-itk libapache2-mod-rpaf libapache2-mod-auth-mysql --force-yes -y
# ставим  php5 и его зависимости.
apt-get install php5-common php5 libapache2-mod-php5 php5-cli php5-cgi php5-mysql --force-yes -y
# ставим доп пакеты php
apt-get install libapache2-mod-php5 php5 php5-common php5-curl php5-dev php5-mysql php5-gd php5-mcrypt php5-xmlrpc --force-yes -y
# ребутим apache2
/etc/init.d/apache2 restart
# ставим mysql
apt-get install mysql-server mysql-client --force-yes -y
# ставим phpmyadmin
apt-get install phpmyadmin --force-yes -y


# активируем mod rewrite для apache2
a2enmod rewrite


# заворачиваем apache2 на 81-ый порт
echo "NameVirtualHost *:81
Listen 127.0.0.1:81
<IfModule mod_ssl.c>
    # SSL name based virtual hosts are not yet supported, therefore no
    # NameVirtualHost statement here
    Listen 443
</IfModule>" > /etc/apache2/ports.conf


echo "ServerName    localhost" > /etc/apache2/httpd.conf

#добавим имя хоста
echo "ServerName localhost" | tee /etc/apache2/conf.d/fqdn

#Сделаем настройки, чтобы апач, меньше выдавал о себе информации
FILNAME='/etc/apache2/conf.d/security'
sed -i 's/ServerTokens OS/ServerTokens Prod/g' $FILNAME
sed -i 's/ServerSignature On/ServerSignature Off/g' $FILNAME


# ребутим apache2
/etc/init.d/apache2 restart


# ставим nginx
apt-get install nginx --force-yes -y
# останавливаем nginx
/etc/init.d/nginx stop


# создаем конфиг nginx
echo "# пользователь, от которого запускается процесс
user www-data;
# кол-во рабочих процессов. Обычно равно кол-ву ядер на машине
worker_processes  1;

pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    types_hash_max_size 2048;
    server_names_hash_bucket_size 64;

    sendfile        on;
    tcp_nopush     on;

    keepalive_timeout  2;
    tcp_nodelay        on;

    gzip  on;
    gzip_comp_level 3;
    gzip_proxied any;
    gzip_types text/plain html text/css application/x-javascript text/xml application/xml application/xml+rss text/javascript;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}" > /etc/nginx/nginx.conf


# создаем файл проксирования
echo 'proxy_redirect              off;
proxy_set_header            X-Real-IP $remote_addr;
proxy_set_header            X-Forwarded-For $proxy_add_x_forwarded_for;
client_max_body_size        10m;
client_body_buffer_size     128k;
proxy_connect_timeout       90;
proxy_send_timeout          90;
proxy_read_timeout          90;
proxy_buffer_size           4k;
proxy_buffers               4 32k;
proxy_busy_buffers_size     64k;
proxy_headers_hash_max_size 51200;
proxy_headers_hash_bucket_size 6400;
proxy_temp_file_write_size  64k;' > /etc/nginx/proxy.conf


# ставим mod_rpaf
apt-get install libapache2-mod-rpaf --force-yes -y
# правим mod_rpaf
echo "<IfModule mod_rpaf.c>
     # Включаем модуль
     RPAFenable On

     # Приводит в порядок X-Host
     RPAFsethostname On

     # Адрес фронтенда (nginx)      
     RPAFproxy_ips 127.0.0.1 $EXT_IP
</IfModule>" > /etc/apache2/mods-enabled/rpaf.conf


# ставим memcached
apt-get install memcached php5-memcache --force-yes -y


# ставим Zend Optimizer
#Определить архитектуру и операционную систему, которая установлена у вас на сервере, можно выполнив команду uname -a
# качаем исходники Для 64-битной архитектуры (x86_64/amd64)
# wget http://files.besthost.by/programm/ZendOptimizer/ZendOptimizer-3.3.9-linux-glibc23-x86_64.tar.gz # нужное раскоментировать
# качаем исходники Для 32-разрядных операционных систем (архитетура i386/i686)
#wget http://files.besthost.by/programm/ZendOptimizer/ZendOptimizer-3.3.9-linux-glibc23-i386.tar.gz # нужное раскоментировать
#распаковываем архив Для 32-разрядных операционных систем (архитетура i386/i686)
#tar xzvf ZendOptimizer-3.3.9-linux-glibc23-i386.tar.gz # нужное раскоментировать
#распаковываем архив Для 64-битной архитектуры (x86_64/amd64)
#tar xzvf ZendOptimizer-3.3.9-linux-glibc23-x86_64.tar.gz # нужное раскоментировать
#cd ZendOptimizer-3.3.9-linux-glibc23-x86_64/data/5_2_x_comp
#cd ZendOptimizer-3.3.9-linux-glibc23-i386/data/5_2_x_comp
# копируем модуль в папку к модулям PHP
#cp ZendOptimizer.so /usr/lib/php5/
#Debian Linux имеет различные файлы конфигурации для разных режимов работы PHP. В нашем случае эти файлы имеют имена.
#/etc/php5/apache2/php.ini
#/etc/php5/cgi/php.ini
#/etc/php5/cli/php.ini
# Чтобы не добавлять строку zend_extension во все файлы можно создать один файл
#echo 'zend_extension=/usr/lib/php5/ZendOptimizer.so' > /etc/php5/conf.d/zend.ini

#rm -r ${ROOT_PATH}/ZendOptimizer-3.3.9-linux-glibc23-i386.tar.gz
#rm -rf ${ROOT_PATH}/ZendOptimizer-3.3.9-linux-glibc23-i386



# Ребутим apache2
/etc/init.d/apache2 restart


# Ставим eaccelerator
# Ставим все необходимое для сборки
apt-get install -y php5-dev bzip2 make --force-yes -y
# Качаем исходники
wget http://files.besthost.by/programm/eaccelerator-0.9.6.1/eaccelerator.tar.gz
#распаковываем архив
tar xzvf eaccelerator.tar.gz
# переходим в распакованный каталог
cd eaccelerator-0.9.6.1
# Компилируем
phpize5
./configure
make
make install
cd ..
rm -rf ./eaccelerator-0.9.6.1
rm -rf ./eaccelerator.tar.gz


# Создаем конфиг файл
echo 'extension="eaccelerator.so"
; размер shm памяти в мегабайтах
eaccelerator.shm_size="32"
eaccelerator.cache_dir="/opt/eaccelerator"
eaccelerator.enable="1"
eaccelerator.optimizer="1"
eaccelerator.check_mtime="1"
eaccelerator.debug="0"
eaccelerator.filter=""
eaccelerator.shm_max="0"
eaccelerator.shm_ttl="0"
eaccelerator.shm_prune_period="0"
; памяти у нас много, будем кэшировать в ней
eaccelerator.shm_only="1"
; рекомендую отлючить
eaccelerator.compress="0"
eaccelerator.compress_level="9" ' > /etc/php5/conf.d/eaccelerator.ini


#Очищаем систему после сборки
apt-get remove php5-dev --force-yes -y
apt-get autoremove --force-yes -y


# создаем рабочий каталог для eaccelerator
mkdir /opt/eaccelerator


# задаем права на каталог
chmod 0777 /opt/eaccelerator


# Ребутим apache2
/etc/init.d/apache2 restart
# Ребутим nginx
/etc/init.d/nginx restart
