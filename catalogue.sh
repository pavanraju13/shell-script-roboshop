#!/bin/bash

#!/bin/bash
TIME_STAMP=$( date +%Y-%m-%d_%H-%M-%S )
USER_ID=$( id -u )
SCRIPT_NAME=$(basename $0 | cut -d "." -f1 )
LOG_FILE=/var/log/$SCRIPT_NAME.log
USER=roboshop
DIR=/app
Temp_Folder=/tmp/catalogue.zip
Current_Path=$pwd
Service=/etc/systemd/system/catalogue.service
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
echo -e "${G} $2 successfully ${N}" 
else
echo -e "${R} $2 not successful ${N}"
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

dnf list module nodejs  &>> $LOG_FILE  #List the nodejs versions
RESULT $? "Nodejs module"

dnf module disable nodejs -y &>> $LOG_FILE #Disable the current nodejs module/version
RESULT $? "Disable nodejs"

dnf module enable nodejs:20 -y &>> $LOG_FILE #enable nodejs 20 version
RESULT $? "Disable nodejs"

dnf install nodejs -y &>> $LOG_FILE #Installing the nodejs
RESULT $? "Disable nodejs"

id $USER              #checking user present or not
if [ $? -ne 0 ]     
then
echo "$USER is not created ...creating the user" &>> $LOG_FILE
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
RESULT $? "User created"
else
echo -e "$USER is already created..$Y skipping $N"
RESULT $? "User already created"
fi

if [ -e $DIR ]
then
echo "$DIR directory exists."
else 
echo "$DIR directory not exists.creating a directory"
mkdir $DIR
RESULT $? "Directory created"
fi

curl -o $Temp_Folder https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOG_FILE
RESULT $? "downloaded the code into the $Temp_Folder"

cd $DIR
RESULT $? "Switched to $DIR"
unzip $DIR 
RESULT $? "unzipped the application code"

cp $Current_Path/catalogue_service.sh  $Service &>> $LOG_FILE
RESULT $? "Service configuration file copied"

systemctl daemon-reload &>> $LOG_FILE
RESULT $? "deamon reload"

systemctl enable catalogue &>> $LOG_FILE
systemctl start catalogue &>> $LOG_FILE
RESULT $? "Enabled and started"

cp $Current_Path/mongo-repo.sh $REPO_FILE &>> $LOG_FILE
RESULT $? "copied the mongod repo content"

dnf install mongodb-mongosh -y &>> $LOG_FILE
RESULT $? "Installed the mongodb" 

mongosh --host mongodb.clouddevops.life </app/db/master-data.js  &>> $LOG_FILE
RESULT $? "Load the schema"

curl http://localhost:8080/health

#mongosh --host mongodb.clouddevops.life &>> $LOG_FILE
#RESULT $? "connecting to the mongodb"








