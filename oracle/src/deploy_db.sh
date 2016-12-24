#!/bin/ksh

RUNDATE=`date +%Y%m%d-%H%M%S`
export RUNDATE

if [ -z $DDB_DEPLOY_DBHOME ]; then
   echo "ERROR: DEPLOY_DB_HOME is NOT set"
   exit 1
fi

echo [$DDB_DEPLOY_DBHOME]

if [ $# -lt 1 ]; then
   echo "ERROR: Usage deploy_db.sh <sqlfile> [-e] "
   echo "-e option is to execute into sqlplus"
   exit 1
fi

RUNSQL_OUTPUT=$DDB_DEPLOY_DBHOME/log/deploy_db_$RUNDATE.log
EXEC_SQL_FLAG=N

if [ $# == 2 ]; then
   if [ "$2" = "-e" ]; then
      EXEC_SQL_FLAG=Y
   fi
fi

. $DDB_DEPLOY_DBHOME/src/sqlminus.sh $1
echo "Deploy Db output : $DB_OUTPUT_FILE"

. $DDB_DEPLOY_DBHOME/src/getDbPass.sh $DB_OUTPUT_FILE
echo "Completed Deploy Db sql file : $DDB_OUTPUT_FILENAME"

if [  "$EXEC_SQL_FLAG" = "Y" ]; then
     sqlplus /nolog < $DDB_OUTPUT_FILENAME >  $RUNSQL_OUTPUT
     echo "Check the output of sqlplus in : $RUNSQL_OUTPUT"
fi

rm -f $DDB_OUTPUT_FILENAME

unset DB_OUTPUT_FILE
unset DDB_OUTPUT_FILENAME

exit 0
