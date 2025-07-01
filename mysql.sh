#!/bin/bash

TIME_STAMP=$( date +%Y-%m-%d_%H-%M-%S )
USER_ID=$( id -u )
SCRIPT_NAME=$(basename $0 | cut -d "." -f1 )
LOG_FILE=/var/log/$SCRIPT_NAME.log

# Color Codes
R="\e[31m"   # Red
G="\e[32m"   # Green
B="\e[33m"   # Blue
Y="\e[34m"   # Yellow
M="\e[35m"   # Magenta
N="\e[0m"    # Normal

echo "Script started at $TIME_STAMP" | tee -a $LOG_FILE

# Function to check result
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
  echo -e "${R}Error: Permission denied. You don't have root privileges.${N}" | tee -a $LOG_FILE
  exit 1
else
  echo -e "${G}You are a root user${N}" | tee -a $LOG_FILE
fi

# Get MySQL credentials
echo "Enter the username of MySQL:" | tee -a $LOG_FILE
read -s MYSQL_USERNAME
echo "Enter the password of MySQL:" | tee -a $LOG_FILE
read -s MYSQL_PASSWORD

# Validate credentials (basic check)
if [[ "$MYSQL_USERNAME" == "root" && "$MYSQL_PASSWORD" == "RoboShop@1" ]]; then
  echo "Credentials are valid" | tee -a $LOG_FILE
else
  echo "Credentials are not valid" | tee -a $LOG_FILE
  exit 3
fi

# Install MySQL
dnf install mysql-server -y &>> $LOG_FILE
RESULT $? "Installing MySQL"

# Enable and start MySQL service
systemctl enable mysqld &>> $LOG_FILE
systemctl start mysqld &>> $LOG_FILE
RESULT $? "Enabled and started MySQL"

# Test MySQL login
mysql -u"$MYSQL_USERNAME" -p"$MYSQL_PASSWORD" -e "exit" &>> $LOG_FILE
if [ $? -ne 0 ]; then
  echo "Password is incorrect or not set. Running mysql_secure_installation..." | tee -a $LOG_FILE
  mysql_secure_installation --set-root-pass "$MYSQL_PASSWORD" &>> $LOG_FILE
  RESULT $? "Configured the root password for MySQL"
else
  echo "MySQL password already set. Skipping secure installation." | tee -a $LOG_FILE
fi

# Script end
END_TIME=$( date +%Y-%m-%d_%H-%M-%S )
echo "Script successfully completed at $END_TIME" | tee -a $LOG_FILE
