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

LOGFILE=$DDB_LOGDIR/getDbPass-$RUNDATE.log

echo $DDB_DEPLOY_DBHOME

if [ $# -lt 1 ]; then
   echo "ERROR : Usage getDbPass <inputfilename>"
   exit 1
fi

showEcho() {

   echo "getDbPass: $1"
   echo "getDbPass: `date +%Y%m%d-%H%M%S` : $1" >> $LOGFILE

}

INPUT_FILENAME=$1
DDB_OUTPUT_FILENAME=$DDB_DEPLOY_DBHOME/temp/run_$RUNDATE.sql
export DDB_OUTPUT_FILENAME

showEcho "Start update DB clear password"

if [ ! -f $INPUT_FILENAME ]; then
   showEcho "Error $INPUT_FILENAME doesnot exist"
   exit 2
fi

>$DDB_OUTPUT_FILENAME

while read line
do
  
 # Change the password

 echo "$line" | sed 's/^[ \t]*//g' | grep -i "^connect"  > /dev/null
 if [ $? -eq 0 ]; then

    showEcho "Change the password here - $line" 

    CONNECT_PARAM_STRING=`echo "$line" |  sed 's/^[ \t]*//g' | cut -d" " -f2`

    DB_SCHEMA_ID=`echo "$CONNECT_PARAM_STRING" | sed 's/^[ \t]*//g' | cut -d"/" -f1`
    DB_INSTANCE=`echo "$CONNECT_PARAM_STRING" | sed 's/^[ \t]*//g' | cut -d"@" -f2`
    
    grep "$DB_SCHEMA_ID,$DB_INSTANCE" $DDB_DBFILE > /dev/null
    if [ $? -ne 0 ]; then
       showEcho "Error The DB entry is not maintained"
       exit 3  
    fi 
    noofMatch=`grep "$DB_SCHEMA_ID,$DB_INSTANCE" $DDB_DBFILE | wc -l`
    if [ $noofMatch -ne 1 ]; then
       showEcho "Error There are Duplicate entries in the DB file" 
       exit 4
    fi
    
    DB_PASSWORD=`grep "$DB_SCHEMA_ID,$DB_INSTANCE" $DDB_DBFILE | cut -d" " -f2`

    decp_outfile=$DDB_LOGDIR/decp_$RUNDATE.out

    >$decp_outfile

    $DDB_DEPLOY_DBHOME/src/decryptpass $DB_PASSWORD $decp_outfile
    errMatch=`egrep -i "error|exception" $decp_outfile | wc -l`
    if [ $errMatch -eq 0 ]; then
        CLEAR_DB_PASSWORD=`tail -1 $decp_outfile`; 
    else
       showEcho "Error Exception while decrypt the password"
       exit 5
    fi 

    >$decp_outfile
    
    echo "CONNECT $DB_SCHEMA_ID/$CLEAR_DB_PASSWORD@$DB_INSTANCE" >> $DDB_OUTPUT_FILENAME 

    unset CLEAR_DB_PASSWORD

 else
     echo "$line" >> $DDB_OUTPUT_FILENAME
 fi
  
done < $INPUT_FILENAME

showEcho "DB password clear completed"

