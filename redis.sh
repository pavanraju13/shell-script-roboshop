#!/bin/bash
TIME_STAMP=$( date +%Y-%m-%d_%H-%M-%S )
START_TIME_STAMP=$( date +%S )
END_TIME_STAMP=$( date +%S )
Conf_File=/etc/redis/redis.conf
USER_ID=$( id -u )
SCRIPT_NAME=$(basename $0 | cut -d "." -f1 )
LOG_FILE=/var/log/$SCRIPT_NAME.log
pkg=redis

R="\e[31m"   #Red color
G="\e[32m"   #Green color
B="\e[33m"   #Blue color
Y="\e[34m"   #Yellow color
M="\e[35m"   #Magenita colr
N="\e[0m"     #Normal color

echo "script started excution at $TIME_STAMP"
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

dnf module disable $pkg -y &>> $LOG_FILE
RESULT $? "Disable defualt $pkg"

dnf module enable $pkg:7 -y &>> $LOG_FILE
RESULT $? "Enable $pkg:7"

dnf install $pkg -y &>> $LOG_FILE
RESULT $? "Installing $pkg"


sed -i -e 's/127.0.0.1/0.0.0.0/g' -e 's/^protected-mode .*/protected-mode no/' "$Conf_File" &>> $LOG_FILE
RESULT $? "Changing the listner port and protected mode"

systemctl enable $pkg &>>$LOG_FILE
systemctl start $pkg &>>$LOG_FILE
RESULT $? "Enable and started $pkg"

Total_time=$(( $END_TIME_STAMP - $START_TIME_STAMP ))
Script excuted successfully at $Total_time seconds.




