#!/bin/bash

timestamp=`date "+%Y-%m-%d"`

export ORACLE_SID=pm
expdp BKP/BACKUP DIRECTORY=dmpdir DUMPFILE=pm_$timestamp.dmp
sleep 20s
export ORACLE_SID=cm
expdp BKP/BACKUP DIRECTORY=dmpdir DUMPFILE=cm_$timestamp.dmp
sleep 20s
export ORACLE_SID=bi
expdp BKP/BACKUP DIRECTORY=dmpdir DUMPFILE=bi_$timestamp.dmp
