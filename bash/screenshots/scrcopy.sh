#!/bin/bash
#moving all screenshots to win share

###var section###
SRV="192.168.50.125"            # server name or IP
SHARENAME='scrlog'              # shared folder on remote smb server
MNTFOLDER='/home/spy/winsrv/'   # local folder for mount
PINGCOUNT=2                     # requests count
SRVUSRNAME='spy'                # remote user name
SRVPASSWD='gWjmtF6Cxz6B7RCO'    # remote user password
LOGFILE='/var/log/scrcopy.log'  # file for loging
RSYNCPARAMS='-r --ignore-existing'
EXCLFILE='/usr/local/bin/exclude-list.txt'      # rsync exclude file list
SRC='/home/spy/'                # copy from
PROGNAME=$(basename $0)         # program name
###

for myHost in $SRV
do
    # server is online?
    count=$(ping -c $PINGCOUNT $myHost | grep 'received' | awk -F',' '{ print $2 }' | awk '{ print $1 }')
    if [ $count -eq 0 ]; then
        # 100% failed (server down)
        echo "$(date) : $myHost is down (ping failed)" >> $LOGFILE
    else
        # server online
        mount -t cifs //$myHost/$SHARENAME $MNTFOLDER -o username=$SRVUSRNAME,password=$SRVPASSWD,iocharset=utf8,file_mode=077$
        # share mounted?
        if [ "$?" = "0" ]; then
            cd $SRC 2>> $LOGFILE
            sleep 2
            rsync $RSYNCPARAMS --exclude-from $EXCLFILE ${SRC}* $MNTFOLDER 2>> $LOGFILE
            umount $MNTFOLDER 2>> $LOGFILE
            sleep 2
            find ! -name "winsrv" ! -name ".*" ! -name ".cache*" -delete 2>> $LOGFILE
            echo "$(date) : copy session successfully" >> $LOGFILE
        else
            # mount error
            echo "$(date) : mount error" >> $LOGFILE
            exit 1
        fi
    fi
done