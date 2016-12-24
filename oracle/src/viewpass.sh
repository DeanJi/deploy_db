#!/bin/ksh

if [ -z $RUNDATE ]; then
   RUNDATE=`date +%Y%m%d-%H%M%S`
   export RUNDATE
fi

if [ -z $DDB_DEPLOY_DBHOME ]; then
   echo "ERROR: DEPLOY_DB_HOME is NOT set"
   exit 1
fi

DDB_LOGDIR=$DDB_DEPLOY_DBHOME/log
DDB_DBFILE=$DDB_DEPLOY_DBHOME/pwd/db.p

LOGFILE=$DDB_LOGDIR/viewpass-$RUNDATE.log

showEcho() {
 
   echo "viewpass: $1" 
   echo "viewpass: `date +%Y%m%d-%H%M%S` : $1" >> $LOGFILE

}

if [ ! -f $DDB_DBFILE ]; then
   showEcho "ERROR: $DDB_DBFILE doesnot exists"
   exit 1
fi

lcount=`cat $DDB_DBFILE | wc -l`
if [ $lcount -le 1 ]; then
   showEcho "ERROR: DB File is empty"
   exit 2
fi

if [ $# -lt 1 ]; then
   cat $DDB_DBFILE  
fi

if [ $# -eq 1 ]; then
   head -1 $DDB_DBFILE
   cat $DDB_DBFILE | grep "$1" 
fi

if [ $# -eq 2 ]; then
   head -1 $DDB_DBFILE
   cat $DDB_DBFILE | grep "$1" | grep "$2"
fi



