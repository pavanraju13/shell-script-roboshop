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

# Color codes
R="\e[31m"
G="\e[32m"
B="\e[33m"
Y="\e[34m"
M="\e[35m"
N="\e[0m"

# MySQL credentials
echo "Enter MYSQL_USERNAME:"
read -s MYSQL_USERNAME
echo "Enter MYSQL_PASSWORD:"
read -s MYSQL_PASSWORD

echo "Script started at $TIME_STAMP" | tee -a $LOG_FILE

# Function to handle result checks
RESULT() {
  if [ $1 -eq 0 ]; then
    echo -e "$2.. ${G}successfully${N}"
  else
    echo -e "$2.. ${R}failure${N}"
    exit 2
  fi
}

# Root access check
if [ $USER_ID -ne 0 ]; then
  echo -e "${R}Error: You don't have root privileges${N}" | tee -a $LOG_FILE
  exit 1
else
  echo -e "${G}You are a root user${N}" | tee -a $LOG_FILE
fi

# Install pkg1 if not installed
dnf list installed $pkg1 &>> $LOG_FILE
if [ $? -ne 0 ]; then
  echo "$pkg1 is not installed.. ${Y}installing $pkg1${N}"
  dnf install $pkg1 -y &>> $LOG_FILE
  RESULT $? "Installing $pkg1"
else
  echo "$pkg1 already installed"
fi

# Create user if not exists
id $USER &>> $LOG_FILE
if [ $? -ne 0 ]; then
  echo "${M}Creating user $USER${N}"
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" $USER
  RESULT $? "$USER created"
else
  echo -e "${Y}$USER already exists${N}"
fi

# Ensure /app directory exists
if [ ! -d $DIR ]; then
  echo "$DIR directory not exists. Creating..."
  mkdir -p $DIR
  RESULT $? "Directory created"
else
  echo "$DIR directory exists."
fi

# Download and extract code
curl -o $Temp_Folder https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> $LOG_FILE
RESULT $? "Downloaded the code into $Temp_Folder"

cd $DIR
RESULT $? "Switched to $DIR"

rm -rf $DIR/* &>> $LOG_FILE
RESULT $? "Deleted existing content"

unzip $Temp_Folder &>> $LOG_FILE
RESULT $? "Unzipped the application code"

mvn clean package &>> $LOG_FILE
RESULT $? "Maven clean package"

cp $Current_Path/shipping.service $Service &>> $LOG_FILE
RESULT $? "Copied the service configuration"

systemctl daemon-reload &>> $LOG_FILE
systemctl enable shipping &>> $LOG_FILE
systemctl start shipping &>> $LOG_FILE
RESULT $? "Reloaded, Enabled, and Started shipping service"

# Install pkg2 if not installed
dnf list installed $pkg2 &>> $LOG_FILE
if [ $? -ne 0 ]; then
  echo -e "$pkg2 is not installed.. ${Y}installing $pkg2${N}"
  dnf install $pkg2 -y &>> $LOG_FILE
  RESULT $? "Installing $pkg2"
else
  echo "$pkg2 already installed"
fi

# Check schema before loading

TABLE_TO_CHECK="codes"
TABLE_EXISTS=$(mysql -h $hostname -u$MYSQL_USERNAME -p$MYSQL_PASSWORD -e "USE cities; SHOW TABLES LIKE '$TABLE_TO_CHECK';" 2>/dev/null | grep "$TABLE_TO_CHECK")

if [ -z "$TABLE_EXISTS" ]; then
  echo "Table '$TABLE_TO_CHECK' not found. Loading schema..." | tee -a $LOG_FILE
  mysql -h $hostname -u$MYSQL_USERNAME -p$MYSQL_PASSWORD < /app/db/schema.sql &>> $LOG_FILE
  mysql -h $hostname -u$MYSQL_USERNAME -p$MYSQL_PASSWORD < /app/db/app-user.sql &>> $LOG_FILE
  mysql -h $hostname -u$MYSQL_USERNAME -p$MYSQL_PASSWORD < /app/db/master-data.sql &>> $LOG_FILE
  RESULT $? "Loaded schema"
else
  echo "Table '$TABLE_TO_CHECK' already exists. Skipping schema load..." | tee -a $LOG_FILE
fi


systemctl restart shipping &>> $LOG_FILE
RESULT $? "Restart shipping"

END_STAMP=$( date +%Y-%m-%d_%H-%M-%S )
echo "Script completed at $END_STAMP"
