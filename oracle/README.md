# deploy_db
A tool to deploy DB scripts 

1. Oracle DB server is ready
2. JDK, sqlplus are installed in client host
3. In client host, configure tns entry in tnsnames.ora
INSTANCE=(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=xxx.xxx.com)(PORT=1521)))(CONNECT_DATA=(SERVICE_NAME=INSTANCE)))

4. Add "source deploy_db.ksh" in ~/.bashrc
bash-4.1$ cat .bashrc
source /$$APP_HOME$$/deploy_db/oracle/cfg/deploy_db.ksh

5. Run "bash"
6. Run "addpass"
7. Run "deploy_db master.sql -e"


