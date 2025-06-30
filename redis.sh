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