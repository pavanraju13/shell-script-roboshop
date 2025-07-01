#!/bin/bash
TIME_STAMP=$( date +%Y-%m-%d_%H-%M-%S )
USER_ID=$( id -u )
SCRIPT_NAME=$(basename $0 | cut -d "." -f1 )
LOG_FILE=/var/log/$SCRIPT_NAME.log


R="\e[31m"   #Red color
G="\e[32m"   #Green color
B="\e[33m"   #Blue color
Y="\e[34m"   #Yellow color
M="\e[35m"   #Magenita colr
N="\e[0m"     #Normal color

echo "script started at $TIME_STAMP" | tee -a $LOG_FILE
#This is a function
RESULT() {

if [  $1 -eq 0 ]
then
echo -e "$2.. ${G}successfully ${N}" 
else
echo -e "$2..${R} failure ${N}"
exit 2
fi
}

#Checking the root access
if [ $USER_ID -eq 0 ]
then
echo -e "${G} you are a root user ${N}" | tee -a $LOG_FILE
else
echo -e "${R} Error Permission denied you don't have root privileges ${N}" | tee -a $LOG_FILE
exit 1
fi

echo "Enter the username of MYSQL:" | tee -a $LOG_FILE
read -s MYSQL_USERNAME
echo "Enter the password of MYSQL:" | tee -a $LOG_FILE
read -s MYSQL_PASSWORD


dnf install mysql-server -y &>> $LOG_FILE 
RESULT $? "Installing mysql"

systemctl enable mysqld &>> $LOG_FILE
systemctl start mysqld  &>> $LOG_FILE
RESULT $? "Enabled and started"

# Test MySQL login
mysql -u"$MYSQL_USERNAME" -p"$MYSQL_PASSWORD" -e "exit" &>> $LOG_FILE

if [ $? -ne 0 ]; then
  echo "Password is incorrect or not set. Running mysql_secure_installation..." | tee -a $LOG_FILE
  mysql_secure_installation --set-root-pass "$MYSQL_PASSWORD" &>> $LOG_FILE
  RESULT $? "Configured the root password for MySQL"
else
  echo "MySQL password already set. Skipping secure installation." | tee -a $LOG_FILE
fi


END_TIME=$( date +%Y-%m-%d_%H-%M-%S )
echo "script successfully completed at $END_TIME" | tee -a $LOG_FILE


