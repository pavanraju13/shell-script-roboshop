#!/bin/bash

#!/bin/bash
TIME_STAMP=$( date +%Y-%m-%d_%H-%M-%S )
USER_ID=$( id -u )
SCRIPT_NAME=$(basename $0 | cut -d "." -f1 )
LOG_FILE=/var/log/$SCRIPT_NAME.log
REPO_FILE=/etc/yum.repos.d/mongo.repo
USER=roboshop
DIR=/app
Temp_Folder=/tmp/catalogue.zip
Current_Path=/home/ec2-user/shell-script-roboshop
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
RESULT $? "List Nodejs module"

dnf module disable nodejs -y &>> $LOG_FILE #Disable the current nodejs module/version
RESULT $? "Disable default nodejs"

dnf module enable nodejs:20 -y &>> $LOG_FILE #enable nodejs 20 version
RESULT $? "enable nodejs version 20"

dnf install nodejs -y &>> $LOG_FILE #Installing the nodejs
RESULT $? "Installing nodejs"

id $USER   &>> $LOG_FILE        #checking user present or not
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

cd $DIR                                  #switched to the app directory
RESULT $? "Switched to $DIR"

rm -rf /app/* &>> $LOG_FILE                #Deleting the old content
RESULT $? "Deleted the content"

unzip $Temp_Folder &>> $LOG_FILE           #Unzipping the temp folder in app directory
RESULT $? "unzipped the application code"
npm install &>> $LOG_FILE
RESULT $? "Installed npm packages"

cp $Current_Path/catalogue_service.sh  $Service &>> $LOG_FILE     #copying the system conf file to .service
RESULT $? "Service configuration file copied"

systemctl daemon-reload &>> $LOG_FILE   #Reload the deamon
RESULT $? "deamon reload"

systemctl enable catalogue &>> $LOG_FILE    #start enable restart
systemctl start catalogue &>> $LOG_FILE
systemctl restart catalogue &>> $LOG_FILE
RESULT $? "Enabled,started and restarted"

cp $Current_Path/mongo-repo.sh $REPO_FILE &>> $LOG_FILE  #copying the repo content to mongod repo file
RESULT $? "copied the mongod repo content"

dnf install mongodb-mongosh -y &>> $LOG_FILE
RESULT $? "Installed the mongodb" 


mongosh --host mongodb.clouddevops.life </app/db/master-data.js  &>> $LOG_FILE
RESULT $? "Load the schema"

curl http://localhost:8080/health   #check the health of the calaogue 

#mongosh --host mongodb.clouddevops.life &>> $LOG_FILE
#RESULT $? "connecting to the mongodb"

echo "jabil application catalogue component completed"







