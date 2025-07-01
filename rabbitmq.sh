#!/bin/bash
TIME_STAMP=$( date +%Y-%m-%d_%H-%M-%S )
REPO_FILE=/etc/yum.repos.d/rabbitmq.repo
USER_ID=$( id -u )
SCRIPT_NAME=$(basename $0 | cut -d "." -f1 )
LOG_FILE=/var/log/$SCRIPT_NAME.log
Current_Path=/home/ec2-user/shell-script-roboshop
R="\e[31m"   #Red color
G="\e[32m"   #Green color
B="\e[33m"   #Blue color
Y="\e[34m"   #Yellow color
M="\e[35m"   #Magenita colr
N="\e[0m"     #Normal color

echo "Enter rabbitmq username:"
read RABBITMQ_USERNAME
echo "Enter rabbitmq password:"
read -s RABBITMQ_PASSWORD

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
cp $Current_Path/rabbitmq.repo $REPO_FILE &>> $LOG_FILE
RESULT $? "Copied the repo content to the default repo file"

dnf list installed rabbitmq &>> $LOG_FILE
if [ $? -ne 0 ]
then
echo -e "Rabbitmq is not installed..${Y}installing4{N}"
dnf install rabbitmq-server -y &>> $LOG_FILE
RESULT $? "Installing Rabbitmq"

systemctl enable rabbitmq-server &>> $LOG_FILE
systemctl start rabbitmq-server &>> $LOG_FILE
RESULT $? "Enable and started"

#creating user and password for rabbitmq to connect to the database from the backend (payments) component

rabbitmqctl add_user $RABBITMQ_USERNAME $RABBITMQ_PASSWORD &>> $LOG_FILE
RESULT $? "Rabbitmq username and password configured"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $LOG_FILE

