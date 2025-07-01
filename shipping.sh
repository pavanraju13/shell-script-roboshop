#!/bin/bash

#!/bin/bash
TIME_STAMP=$( date +%Y-%m-%d_%H-%M-%S )
USER_ID=$( id -u )
SCRIPT_NAME=$(basename $0 | cut -d "." -f1 )
LOG_FILE=/var/log/$SCRIPT_NAME.log
pkg1=$1
pkg2=$2
USER=roboshop
DIR=/app
Temp_Folder=/tmp/$SCRIPT_NAME.zip
Current_Path=/home/ec2-user/shell-script-roboshop
Service=/etc/systemd/system/$SCRIPT_NAME.service
hostname=mysql.clouddevops.life

R="\e[31m"   #Red color
G="\e[32m"   #Green color
B="\e[33m"   #Blue color
Y="\e[34m"   #Yellow color
M="\e[35m"   #Magenita colr
N="\e[0m"     #Normal color

echo "enter MYSQL_USERNAME:"
echo "enter MYSQL_PASSWORD:"
read -s MYSQL_USERNAME
read -s MYSQL_PASSWORD


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

dnf list installed $pkg1 &>> $LOG_FILE
if [ $? -ne 0 ]
then
echo "$pkg1 is not installed..${Y} installing $pkg1 {N}"
dnf install $pkg1 -y &>> $LOG_FILE
RESULT $? "Installing $pkg1"
else
echo " $pkg1 already installed"
fi

id $USER
if [ $? -ne 0 ]
then
echo "$USER not exists"
echo "${M}Creating a $USER user${N}"
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" $USER
RESULT $? "$USER created"
else
echo "${Y}$USER already created${N}"
fi

if [ -e $DIR ]
then
echo "$DIR directory exists."
else 
echo "$DIR directory not exists.creating a directory"
mkdir $DIR
RESULT $? "Directory created"
fi

curl -o $Temp_Folder https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>> $LOG_FILE
RESULT $? "downloaded the code into the $Temp_Folder"

cd $DIR                                  #switched to the app directory
RESULT $? "Switched to $DIR"

rm -rf /app/* &>> $LOG_FILE                #Deleting the old content
RESULT $? "Deleted the content"

unzip $Temp_Folder &>> $LOG_FILE           #Unzipping the temp folder in app directory
RESULT $? "unzipped the application code"

mvn clean package                           #installing all the dependencies
RESULT $? "mvn clean install"

cp $Current_Path/shipping.service $Service &>> $LOG_FILE
RESULT $? "copied the service conf"

systemctl daemon-reload &>> $LOG_FILE
systemctl enable shipping &>> $LOG_FILE
systemctl start shipping &>> $LOG_FILE
RESULT $? "Reload,Enabled and Started"

dnf list installed $pkg &>> $LOG_FILE
if [ $? -ne 0 ]
then
echo "$pkg2 is not installed..${Y} installing $pkg2 {N}"
dnf install $pkg2 -y &>> $LOG_FILE
RESULT $? "Installing $pkg2"
else
echo " $pkg2 already installed"
fi
# Set a sample table to check
TABLE_TO_CHECK="users"  # Change this to any known table that will exist after loading

# Check if the table exists
TABLE_EXISTS=$(mysql -h $hostname -u$MYSQL_USERNAME -p$MYSQL_PASSWORD -e "USE roboshop; SHOW TABLES LIKE '$TABLE_TO_CHECK';" 2>/dev/null | grep "$TABLE_TO_CHECK")

if [ -z "$TABLE_EXISTS" ]; then
  echo "Schema not found. Loading now..." | tee -a $LOG_FILE
  mysql -h $hostname -u$MYSQL_USERNAME -p$MYSQL_PASSWORD < /app/db/schema.sql &>> $LOG_FILE
  mysql -h $hostname -u$MYSQL_USERNAME -p$MYSQL_PASSWORD < /app/db/app-user.sql &>> $LOG_FILE
  mysql -h $hostname -u$MYSQL_USERNAME -p$MYSQL_PASSWORD < /app/db/master-data.sql &>> $LOG_FILE
  RESULT $? "Schema loaded"
else
  echo "Schema already loaded. Skipping..." | tee -a $LOG_FILE
fi

systemctl restart shipping &>> $LOG_FILE
RESULT $? 'restart shipping"

END_STAMP=$( date +%Y-%m-%d_%H-%M-%S )
echo "scrript completed at $END_STAMP"




