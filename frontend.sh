#!/bin/bash

#setting up the variables
TIME_STAMP=$( date +%Y-%m-%d_%H-%M-%S )
USER_ID=$( id -u )
SCRIPT_NAME=$(basename $0 | cut -d "." -f1 )
LOG_FILE=/var/log/$SCRIPT_NAME.log
USER=roboshop
DIR=/app
Temp_Folder=/tmp/$SCRIPT_NAME.zip
Current_Path=/home/ec2-user/shell-script-roboshop
conf=/etc/nginx/nginx.conf
pkg=nginx
main_file=/usr/share/nginx/html


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

dnf list $pkg &>> $LOG_FILE #Listed nginx
RESULT $? "List $pkg"

dnf module disable $pkg -y &>> $LOG_FILE #disable nginx module
RESULT $? "Disable $pkg"

dnf module enable $pkg:1.24 -y &>> $LOG_FILE  #enable nginx module
RESULT $? "Enable $pkg" 

dnf install $pkg -y &>> $LOG_FILE #install nginx
RESULT $? "Installing $pkg"


rm -rf $main_file/* &>> $LOG_FILE
RESULT $? "Deleted the old content"

curl -o $Temp_Folder https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> $LOG_FILE
RESULT $? "download the code to the tmp directory"

cd $main_file &>> $LOG_FILE
unzip $Temp_Folder &>> $LOG_FILE
RESULT $? "Unzipped the folder"

cp $Current_Path/$pkg.conf $conf &>> $LOG_FILE
RESULT $? "Copied the conf file"

systemctl restart $pkg &>> $LOG_FILE
RESULT $? "Restarted $pkg"




