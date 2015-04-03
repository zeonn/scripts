#vars
DB_NAME="database"
DB_USER="username"
DB_PASS="password"
WEB_DIR="/var/www"
SITE_NAME="mysite.com"
BACKUP_DIR="/home/zeon/backup/mysite"

# Database
/usr/bin/mysqldump -u $DB_USER -p$DB_PASS $DB_NAME | gzip > $BACKUP_DIR/db_`date +%y_%m_%d`.gz

# Files
rsync -a $WEB_DIR/$SITE_NAME $BACKUP_DIR
