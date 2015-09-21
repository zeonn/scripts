#!/bin/bash

EDIR="edited"
FILEMASK="*.jpg *.jpeg *.JPG *.png *.bmp *.gif"
PARAMS="-resize 800x800 -watermark 90.0 -gravity Center watermark.png"
WORKDIR="/home/zeon/photos"
RUNDIR="/home/zeon/watermark"

cd $RUNDIR
cp watermark.png $WORKDIR
cd $WORKDIR
mkdir $EDIR
for i in ${FILEMASK}
do
	composite $PARAMS "$i" "${EDIR}/${i%.jpg}.jpg"
done
rm -f "${EDIR}/watermark.png.jpg"
rm -f watermark.png

