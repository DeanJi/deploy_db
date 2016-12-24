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
BAK_DDB_DBFILE=$DDB_DEPLOY_DBHOME/pwd/db.p_$RUNDATE
TEMP_DDB_DBFILE=$DDB_DEPLOY_DBHOME/pwd/temp_db.p

LOGFILE=$DDB_LOGDIR/editpass-$RUNDATE.log

showEcho() {
 
   echo "editpass: $1" 
   echo "editpass: `date +%Y%m%d-%H%M%S` : $1" >> $LOGFILE

}

if [ ! -f $DDB_DBFILE ]; then
   showEcho "$DDB_DBFILE doesnot exists"
   exit 1
else
   cp -p $DDB_DBFILE $BAK_DDB_DBFILE
fi

getRecordValue() {

  printf "Enter DB Schema Id "
  read DBSchema
  printf "Enter DB Instance name "
  read DBInstance

  export DBSchema
  export DBInstance

  if [ ! -z $DBSchema ]; then
     showEcho  "DB Schema is $DBSchema"
  fi
  if [ ! -z $DBInstance ]; then
     showEcho  "DB Instance is $DBInstance"
  fi

  schema_count=0

  schema_count=`grep -i "^$DBSchema\,$DBInstance" $DDB_DBFILE | grep -v grep | wc -l`
  showEcho "DB user and instance count in $DDB_DBFILE $schema_count"

  if [ $schema_count -ne 1 ]; then
     showEcho "Schemaid $DBSchema and Instance $DBInstance does not exists in the DB file $DDB_DBFILE"
     return 1
  fi

  getPass

  if [ -z $passwd1 ]; then
     return 1     
  else
     showEcho "Encrypt the input password"
  fi

  encp_outfile=$DDB_LOGDIR/encp_$RUNDATE.out

  >$encp_outfile

  unset ENC_DB_PASSWORD

  $DDB_DEPLOY_DBHOME/src/encryptpass $passwd1 $encp_outfile
  errMatch=`egrep -i "error|exception" $encp_outfile | wc -l`
  if [ $errMatch -eq 0 ]; then
     ENC_DB_PASSWORD=`tail -1 $encp_outfile`; export ENC_DB_PASSWORD
     if [ ! -z $ENC_DB_PASSWORD ]; then

       >$TEMP_DDB_DBFILE

       while read line
       do

         echo $line 

         schema_count=`echo $line | grep -i "^$DBSchema\,$DBInstance" | grep -v grep | wc -l`
         showEcho "DB user and instance count in $DDB_DBFILE $schema_count"

         if [ $schema_count -eq 1 ]; then
            echo "$DBSchema,$DBInstance $ENC_DB_PASSWORD" >> $TEMP_DDB_DBFILE
         else
            echo $line >> $TEMP_DDB_DBFILE
         fi

       done < $DDB_DBFILE

       showEcho "Password entry modified .. for $DBSchema and $DBInstance"
       if [ -s $TEMP_DDB_DBFILE ]; then
          showEcho "Temp Password moved to Orginal file"
          mv $TEMP_DDB_DBFILE $DDB_DBFILE
       fi
     else 
       showEcho "Password is NULL and Not modified .. for $DBSchema and $DBInstance"
     fi
  else
     showEcho "Error in encryption `cat $encp_outfile`"
     showEcho "Password entry Not modified .. for $DBSchema and $DBInstance"
  fi

  >$encp_outfile
  
}

validatePass() {

  pass1=$1
  pass2=$2

  #showEcho "pass 1 - [$pass1] "
  #showEcho "pass 2 - [$pass2] "

  if [ $pass1 != $pass2 ]; then
     tput smso
     showEcho "Password entered doesnot match"
     tput rmso
     return 0
  else
     showEcho "Password accepted for encryption" 
     return 1
  fi

}

getPass() {

  i=1
  while [ $i -le 3 ];
  do
    trap 'stty echo' 0
    printf '\nPlease enter DB password: '
    #tput smacs
    stty -echo
    read passwd1
    #tput rmacs
    stty echo
    printf '\nPlease re-enter DB password: '
    stty -echo
    read passwd2
    #tput rmacs
    stty echo
    echo
    #echo "passwd entered: $passwd"

    validatePass $passwd1 $passwd2

    if [ $? -eq 1 ]; then
       showEcho "Correct Password ...."
       break
    else
      passwd1=
      passwd2=
    fi
    i=$i+1
 done;

 export passwd1

}

editRecord() {
  getRecordValue
}

editRecord
