#!/bin/ksh

DDB_CONFIG_DIR=${$$APP_HOME$$}/deploy_db/oracle
JAVA_HOME=/usr

CONFIG_FILE=$DDB_CONFIG_DIR/cfg/deploy_db.cfg


if [ ! -f $CONFIG_FILE ]; then
   echo "ERROR: $CONFIG_FILE is missing" 
   exit 1
fi

DDB_DEPLOY_DBHOME=`grep "^DDB_DEPLOY_DBHOME" $CONFIG_FILE | cut -d"=" -f2`


if [ -z $JAVA_HOME ]; then
   echo "ERROR: JAVA_HOME parameter is not set"
   exit 3
else
   if [ -x $JAVA_HOME/bin/java ] ; then 
   	export JAVA_HOME
   else
	echo "ERROR: $JAVA_HOME/bin/java does not exists or not executable"	
	exit 5
   fi
fi
if [ -z $DDB_DEPLOY_DBHOME ]; then
   echo "ERROR: DDB_DEPLOY_DBHOME parameter missing in $CONFIG_FILE"
   exit 2
else
   export DDB_DEPLOY_DBHOME
   if [[ $- == *i* ]]; then
        echo " Deploy_DB has been sourced SUCCESSFULLY"
        echo " Following commands are available "
        echo "  deploy_db - to run master.sql"
        echo "  addpass   - to add new password into password key file"
        echo "  delpass   - to delete existing password from password key file"
        echo "  editpass  - to change the password in password key file"
        echo "  viewpass  - to view encrypted password"
        echo "  whichdb   - to know which DB script is souurced in the current shell"
   fi
fi



alias addpass=$DDB_DEPLOY_DBHOME/src/addpass.sh
alias delpass=$DDB_DEPLOY_DBHOME/src/delpass.sh
alias editpass=$DDB_DEPLOY_DBHOME/src/editpass.sh
alias viewpass=$DDB_DEPLOY_DBHOME/src/viewpass.sh
alias deploy_db=$DDB_DEPLOY_DBHOME/src/deploy_db.sh
alias whichdb='echo Oracle @ $DDB_CONFIG_DIR'
