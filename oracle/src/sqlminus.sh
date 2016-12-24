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

LOGFILE=$DDB_LOGDIR/sqlminus-$RUNDATE.log

echo $DDB_DEPLOY_DBHOME

if [ $# -lt 1 ]; then
   echo "ERROR: Usage sqlminus.sh <inputfilename>"
fi


INPUT_FILE=$1

DB_OUTPUT_FILE=$DDB_DEPLOY_DBHOME/temp/deploy_db_$RUNDATE.sql
export DB_OUTPUT_FILE

TEMP_DB_OUTPUT_FILE=$DDB_DEPLOY_DBHOME/temp/temp_deploy_db_$RUNDATE.sql
RUN_TIME_INPUT_FILE=$DDB_DEPLOY_DBHOME/temp/runtime_db.sql
TEMP_OUTPUT_FILE=$DDB_DEPLOY_DBHOME/temp/temp_sqlminus.sql

showEcho() {

   #echo "sqlminus: $1"
   echo "sqlminus: `date +%Y%m%d-%H%M%S` : $1" >> $LOGFILE

}

getForSed() {
 getForSedValue=`echo "$1"| sed "s.\/.\\\\\\\\/.g"`
 showEcho "getForSed: ******** $1 is changed to $getForSedValue"
 export getForSedValue
}

getVarSed() {
 getVarSedValue=`echo "$1"| sed "s.\/.\\\\\/.g"`
 showEcho "getVarSed: ++++++++ $1 is changed to $getVarSedValue"
 export getVarSedValue
}

getDir() {
 echo "$1" | awk -F"/" '{count=NF; if (NF==1){ str=$_;} else {for (i=1; i<count; i++) {if (i!=1){str=str"/"$i;}else{str=$i;}}}; print str;}'
}

checkParam() {
  showEcho "checkParam: Input value - [$1]"

  para0=
  para1=
  para2=
  para3=
  para4=
  para5=

  noofpara=`echo "$1" | wc -w`

  para0=`echo "$1" | cut -d" " -f1` 
  export para0;

  if [ $noofpara -ge 2 ]; then
    para1=`echo "$1" | cut -d" " -f2`
    getForSed $para1
    para1=$getForSedValue
    export para1;
  fi
  if [ $noofpara -ge 3 ]; then
     para2=`echo "$1" | cut -d" " -f3`
     getForSed $para2
     para2=$getForSedValue
     export para2
  fi
  if [ $noofpara -ge 4 ]; then
     para3=`echo "$1" | cut -d" " -f4`
     getForSed $para3
     para3=$getForSedValue
     export para3
  fi
  if [ $noofpara -ge 5 ]; then
     para4=`echo "$1" | cut -d" " -f5`
     getForSed $para4
     para4=$getForSedValue
     export para4
  fi
  if [ $noofpara -ge 6 ]; then
     para5=`echo "$1" | cut -d" " -f6`
     getForSed $para5
     para5=$getForSedValue
     export para5
  fi
  showEcho "checkParam: Output Parameters - [$para0][$para1][$para2][$para3][$para4][$para5]"
}

replaceParam() {
  showEcho "Replace param Input value - [$1]"
  reppara=
  reppara=`echo "$1" | sed "s/&1/$para1/;s/&2/$para2/;s/&3/$para3/;s/&4/$para4/;s/&5/$para5/;"`; export reppara;
  showEcho "Replaced Parameters - [$reppara]"
}

showEcho "Master file - [$INPUT_FILE] "

INPUT_FILE_DIR=`getDir $INPUT_FILE`
showEcho "Master file dir [$INPUT_FILE_DIR] "

cp -p $INPUT_FILE $RUN_TIME_INPUT_FILE

INPUT_FILE=$RUN_TIME_INPUT_FILE

if [ -f $INPUT_FILE ] ; then

  OUTPUT_FILE=$TEMP_OUTPUT_FILE 

  showEcho "OUTPUT file is $OUTPUT_FILE"

  #start check for any @
  count=`cat $INPUT_FILE | sed 's/^[ \t]*//' | egrep "^@[.&a-zA-Z0-9]|^@@[.&a-zA-Z0-9]" | wc -l`

  showEcho "Count at start of the loop [$count]"

  while [ $count -ne 0 ]
  do

    >$OUTPUT_FILE
    echo " " >> $INPUT_FILE
    while read line
    do
       showEcho "Read line in $INPUT_FILE line [$line]"

       echo $line |  sed 's/^[ \t]*//' | egrep "^@[.&a-zA-Z0-9]|^@@[.&a-zA-Z0-9]" > /dev/null
       if [ $? -eq 0 ] ; then

         # TODO: Check the parameters in the line and append accordingly
         checkParam "$line"
         showEcho "After calling 1 checkparam [$para0][$para1][$para2]"
         if [ ! -z $para1 ]; then
            replaceParam "$line"
            showEcho "After calling 1 replaceParam $reppara" 
            line=$reppara
         fi

         SUBFILE_TEMP=`echo "$para0" | sed "s/^@//g;s/^@//g"`
           
         showEcho "Calling getDir with [$SUBFILE_TEMP]"
     
         SUBFILE_TEMP_DIR=`getDir $SUBFILE_TEMP`

         showEcho "Called SQL [$SUBFILE_TEMP] in directory [$SUBFILE_TEMP_DIR]"

         if [ -f $SUBFILE_TEMP ]; then

            showEcho "-- sqlminus Start: From $SUBFILE_TEMP" 

            echo "-- sqlminus Start: From $SUBFILE_TEMP" >> $OUTPUT_FILE
	    echo " " >> $SUBFILE_TEMP 	
            while read line_temp
            do
               showEcho "Read line in $SUBFILE_TEMP line_temp [$line_temp]"

               echo "$line_temp" |  grep "^@@[.&a-zA-Z0-9]" > /dev/null
               if [ $? -eq 0 ] ; then

                  showEcho "There is a @@ in the file"

                  # TODO: Check the parameters in the line and append accordingly
                  #checkParam "$line_temp"
                  #echo "After calling 2 checkparam [$para0][$para1][$para2]"

                  if [ ! -z $para1 ]; then
                      replaceParam "$line_temp"
                      showEcho "After calling 2 replaceParam $reppara" 
                      line_temp=$reppara
                  fi

                  getVarSed $SUBFILE_TEMP_DIR
                  SED_SUBFILE_TEMP_DIR=$getVarSedValue

                  showEcho "after getVarSed directory [${SED_SUBFILE_TEMP_DIR}]"

                  showEcho "echo $line_temp and sed $SED_SUBFILE_TEMP_DIR as s/^@[@]/@$SUBFILE_TEMP_DIR\//"

                  echo "$line_temp" | sed "s/^@[@]/@$SED_SUBFILE_TEMP_DIR\//" >> $OUTPUT_FILE

               else
                  #Replace parameters in the line and append accordingly

                  replaceParam "$line_temp"

                  if [ ! -z $reppara ]; then
                      showEcho "After calling 3 replaceParam $reppara" 
                      line_temp=$reppara
                  fi

                  echo "$line_temp" >> $OUTPUT_FILE
               fi

             done < $SUBFILE_TEMP

             showEcho "-- sqlminus End: of $SUBFILE_TEMP" 

             echo "-- sqlminus End: of $SUBFILE_TEMP" >> $OUTPUT_FILE

         else

            showEcho "ERR: $SUBFILE_TEMP file does not exists" 

         fi #end if of file 

       else # if the line does not have @ in the beginging
           #Replace parameters in the line and append accordingly

           replaceParam "$line"

           if [ ! -z $reppara ]; then
              showEcho "After calling 4 replaceParam $reppara" 
              line=$reppara
           fi

           echo "$line" >> $OUTPUT_FILE
       fi

    done < $INPUT_FILE
    #end of each read line
    
    showEcho "Move the output file as input again"
    mv $OUTPUT_FILE $INPUT_FILE

    count=`cat $INPUT_FILE | sed 's/^[ \t]*//' | egrep "^@[.&a-zA-Z0-9]|^@@[.&a-zA-Z0-9]" | wc -l`

    showEcho "Count inside the loop  is [$count]"

    if [ $count -eq 0 ] ; then
        mv $INPUT_FILE $DB_OUTPUT_FILE
    fi

  done 
  #end for check for any @

  if [ ! -f $DB_OUTPUT_FILE -o ! -s $DB_OUTPUT_FILE ]; then
     showEcho "$DB_OUTPUT_FILE is empty" 
     cp $INPUT_FILE $DB_OUTPUT_FILE 
  fi


  ## Check if Connect String exists 

  noofconnect=`egrep -i "^connect|^conn" $DB_OUTPUT_FILE | wc -l`
  if [ $noofconnect -eq 0 ];then
     showEcho "ERROR: $DB_OUTPUT_FILE do not have connect" 
     exit 2
  fi

  if [ -f $DB_OUTPUT_FILE ]; then
 
     ## Check for the Connect string and Masking
     ## Include Propmt and echo on

     echo "PROMPT sqlM execution start" > $TEMP_DB_OUTPUT_FILE

     while read db_line 
     do 

        echo "$db_line" | sed 's/^[ \t]*//g' | egrep -i "^connect|^conn"  > /dev/null

        if [ $? -eq 0 ]; then
      
           showEcho "Change the password here" 
           CONNECT_PARAM_STRING=`echo "$db_line" |  sed 's/^[ \t]*//g' | cut -d" " -f2`

           DB_SCHEMA_ID=`echo "$CONNECT_PARAM_STRING" | sed 's/^[ \t]*//g' | cut -d"/" -f1`
           DB_INSTANCE=`echo "$CONNECT_PARAM_STRING" | sed 's/^[ \t]*//g' | cut -d"@" -f2`

           TDB_SCHEMA_ID=
           TDB_INSTANCE=

           noofat=`echo $DB_SCHEMA_ID | grep "@" | wc -l`
           if [ $noofat -gt 0 ];  then
              TDB_SCHEMA_ID=`echo "$DB_SCHEMA_ID" | sed 's/^[ \t]*//g' | cut -d"@" -f1`
              TDB_INSTANCE=`echo "$DB_SCHEMA_ID" | sed 's/^[ \t]*//g' | cut -d"@" -f2`
           fi

           if [ ! -z $TDB_SCHEMA_ID ]; then 
              DB_SCHEMA_ID=$TDB_SCHEMA_ID
           fi
           if [ ! -z $TDB_INSTANCE ]; then
              DB_INSTANCE=$TDB_INSTANCE
           fi

           TDB_INSTANCE=
           noofat1=`echo $DB_INSTANCE | grep "/" | wc -l`
           if [ $noofat1 -gt 0 ]; then
             TDB_INSTANCE=`echo "$DB_INSTANCE" | sed 's/^[ \t]*//g' | cut -d"/" -f1`
           fi 

           if [ ! -z $TDB_INSTANCE ]; then 
              DB_INSTANCE=$TDB_INSTANCE
           fi
       
           echo "CONNECT $DB_SCHEMA_ID/\$\$PASSWORD\$\$@$DB_INSTANCE" >> $TEMP_DB_OUTPUT_FILE
           echo "SET ECHO ON " >> $TEMP_DB_OUTPUT_FILE
        else
            echo "$db_line" >> $TEMP_DB_OUTPUT_FILE
        fi

     done < $DB_OUTPUT_FILE
     echo "PROMPT sqlM execution end" >> $TEMP_DB_OUTPUT_FILE
  
     mv $TEMP_DB_OUTPUT_FILE $DB_OUTPUT_FILE
  else
     showEcho "$DB_OUTPUT_FILE does not exists"
  fi  #if ouptfile exists

else
  showEcho "ERROR: Unable to run. $INPUT_FILE not found"
  exit 1
fi

