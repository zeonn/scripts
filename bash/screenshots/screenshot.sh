#!/bin/sh

# first, do:
#sudo apt-get install imagemagick scrot pngcrush sshpass
#then create script file:
#sudo nano /usr/local/bin/screenshot.sh
#and past this text to it. then:
#sudo chown root:root /usr/local/bin/screenshot.sh
#sudo chmod +x /usr/local/bin/screenshot.sh
#sudo chmod 711 /usr/local/bin/screenshot.sh
#add ssh key:
#sudo ssh spy@192.168.50.1
#and say "yes"
#add to crontab (crontab -e):
#*/10 8-20 * * 1-5 sudo /usr/local/bin/screenshot.sh
#then:
#sudo visudo
#add line:
#<username> ALL= NOPASSWD: /usr/local/bin/screenshot.sh
#(<username> replase to name of user with UID 1000)
#sudo service cron reload

# Storage settings:
SRV='192.168.50.1' #remote server IP for screenshotes storage
SRVUSRNAME='spy' #login for remote server
SRVPASSWD='gWjmtF6Cxz6B7RCO' #password for remote server


SCROTPARAMS='-q 100'
PNGPARAMS='-m 136 -l 9 -q'
# -m 136: pngcrush method [0-200]
# -l: zlib  compression level (9 = best compression)
# -q: quiet
JPGPARAMS='-quality 20'

USRNAME=`getent passwd | awk -F: '$3 == 1000 { print $1 }'`
DATE=`date +%Y-%m-%d`
TIME=`date +%H-%M`
TEMPNAME=$USRNAME-shot.tmp.png


# Make a screenshot and pngcrush it
DISPLAY=:0 scrot $SCROTPARAMS $TEMPNAME
pngcrush $PNGPARAMS $TEMPNAME /tmp/$TEMPNAME && mv /tmp/$TEMPNAME $TEMPNAME

# convert to jpeg
convert $TEMPNAME $JPGPARAMS $TEMPNAME.jpg && rm -f $TEMPNAME

# Give the screenshot its final name
SHOTNAME=$USRNAME-$DATE-$TIME.jpg
mv $TEMPNAME.jpg $SHOTNAME

#creating remote directory (if it not exist)
sshpass -p $SRVPASSWD ssh $SRVUSRNAME@$SRV mkdir -p $USRNAME/$DATE
# move file to remote server
sshpass -p $SRVPASSWD scp -q $SHOTNAME $SRVUSRNAME@$SRV:$USRNAME/$DATE
# delete local file
rm -f $SHOTNAME