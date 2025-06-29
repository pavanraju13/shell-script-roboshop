#!/bin/bash
TIME_STAMP=$( date +%Y-%m-%d_%H-%M-%S )
REPO_FILE=/etc/yum.repos.d/mongo.repo
USER_ID=$( id -u )
SCRIPT_NAME=$(basename $0 | cut -d "." -f1 )
LOG_FILE=/var/log/$SCRIPT_NAME.log
R="\e[31m"   #Red color
G="\e[32m"   #Green color
B="\e[33m"   #Blue color
Y="\e[34m"   #Yellow color
M="\e[35m"   #Magenita colr
N="\e[0m"     #Normal color

#This is a function
RESULT() {

if [  $1 -eq 0 ]
then
echo -e "${G} $2  successfully ${N}" 
else
echo -e "${R} $2 not successfull ${N}"
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

cp /home/ec2-user/shell-script-roboshop/mongo-repo.sh $REPO_FILE #Copying the mongo-repo content to repo_file
RESULT $? "Mongodb"

dnf install mongodb-org -y &>> $LOG_FILE  # Installing the mongodb
RESULT $? "Installing mongodb-org"

systemctl start mongod &>> $LOG_FILE #starting the mongod
RESULT $? "mongod started"

systemctl enable mongod &>> $LOG_FILE #Enabling mongod
RESULT $? "enabled mongod"

sed -i 's/127.0.0.0/0.0.0.0/g' /etc/mongod.conf &>> $LOG_FILE #Replacing the listner port address
RESULT $? "changed the listner port address"

systemctl restart mongod &>> $LOG_FILE  #Starting the mongodb
RESULT $? "mongod restarted"








