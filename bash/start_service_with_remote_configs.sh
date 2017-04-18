#!/bin/bash
# start local service with configs from remote server

# first do:
# ssh-keygen -t rsa
# ssh-copy-id -i ~/.ssh/id_rsa <REMOTE_USER>@<REMOTE_HOST>


# vars:
REMOTE_HOST='remoteserver.com'
REMOTE_PORT='22'
REMOTE_USER='username'
LOCAL_USER='username'
REMOTE_PASSWD='password'
REMOTE_FOLDER='/home/username/openvpn/'
CONF_FOLDER='/etc/openvpn/'
SERVICE='openvpn'

service ${SERVICE} stop
rm -rf ${CONF_FOLDER}*
mkdir ${CONF_FOLDER}
chown -R root:root ${CONF_FOLDER}
mount -t tmpfs tmpfs ${CONF_FOLDER} -o size=10M

until [ $(find ${CONF_FOLDER} -maxdepth 1 -type f | wc -l) == 0 ]; do
        until nc -z $REMOTE_HOST $REMOTE_PORT
        do
            echo "waiting for remote server..."
            sleep 3
        done
        scp -i /home/${LOCAL_USER}/.ssh/id_rsa -r ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_FOLDER}* ${CONF_FOLDER}
done
# chown -R root:root ${CONF_FOLDER}*
service ${SERVICE} start
