#!/bin/bash

DST_IPADDR=91.214.132.14
DST_LOGIN=root

BACKUPDIRS="/home/test1 /home/test2"
TMPDIR="/home/"
timestamp=`date "+%Y_%m_%d"`

err() { echo -e "* Error: $1"; exit 1; }

ssh $DST_LOGIN@$DST_IPADDR 'tar -zcvf '$TMPDIR$DST_IPADDR'_'$timestamp'.tar.gz '$BACKUPDIRS || err "Remote connection failed"
scp $DST_LOGIN@$DST_IPADDR:${TMPDIR}${DST_IPADDR}_${timestamp}.tar.gz ./
ssh $DST_LOGIN@$DST_IPADDR 'rm -f '$TMPDIR$DST_IPADDR'_'$timestamp'.tar.gz' || err "Remote connection failed"