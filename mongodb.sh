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

RESULT() {

if [  $1 -eq 0 ]
then
echo -e "${G} $2  successfully ${N}" 
else
echo -e "${R} $2 not successfull ${N}"
exit 2
fi
}


if [ $USER_ID -eq 0 ]
then
echo -e "${G} you are a root user ${N}"
else
echo -e "${R} Error Permission denied you don't have root privileges ${N}"
exit 1
fi

cp /home/ec2-user/shell-script-roboshop/mongo-repo.sh $REPO_FILE | tee -a $LOG_FILE
RESULT $? "Mongodb"

dnf install mongodb-org -y | tee -a $LOG_FILE
RESULT $? "Installing mongodb-org"

systemctl start mongod | tee -a $LOG_FILE
RESULT $? "mongod started"

systemctl enable mongod | tee -a $LOG_FILE
RESULT $? "enabled mongod"

sed -i 's/127.0.0.0/0.0.0.0/g' /etc/mongod.conf | tee -a $LOG_FILE
RESULT $? "changed the listner port address"

systemctl start mongod | tee -a $LOG_FILE
RESULT $? "mongod started"






