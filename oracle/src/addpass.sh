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

LOGFILE=$DDB_LOGDIR/addpass-$RUNDATE.log

showEcho() {
 
   echo "addpass: $1" 
   echo "addpass: `date +%Y%m%d-%H%M%S` : $1" >> $LOGFILE

}
if [ -f $DDB_DBFILE ] ; then
line_count=`grep -i "^$DBSchema\,$DBInstance" $DDB_DBFILE | wc -l`
if [ $line_count -lt 1 ]; then
        showEcho "Info Password file is empty"
	touch $DDB_DBFILE
        if [ $? -eq 0  ] ; then
              echo "UserID,DBInstance Password" >> $DDB_DBFILE
                showEcho "Info New password file is created"
        else
              echo "Unable to create new password file, check file permissions"
        fi
else
 cp -p $DDB_DBFILE $BAK_DDB_DBFILE
 fi
else
        showEcho "Info Password file does not exist"
        touch $DDB_DBFILE
        if [ $? -eq 0  ] ; then
              echo "UserID,DBInstance Password" >> $DDB_DBFILE
                showEcho "Info New password file is created"
        else
              echo "Unable to create new password file, check file permissions"
        fi
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

  if [ $schema_count -ne 0 ]; then
     showEcho "Schemaid $DBSchema and Instance $DBInstance exists in the DB file $DDB_DBFILE"
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
       echo "$DBSchema,$DBInstance $ENC_DB_PASSWORD" >> $DDB_DBFILE
       showEcho "Password entry added .. for $DBSchema and $DBInstance"
     else 
       showEcho "Password is NULL and Not added .. for $DBSchema and $DBInstance"
     fi
  else
     showEcho "Error in encryption `cat $encp_outfile`"
     showEcho "Password entry Not added .. for $DBSchema and $DBInstance"
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

addRecord() {
  getRecordValue
}

addRecord
