#!/bin/bash

USERID=$(id -u)


R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "script executing at: $(date)" | tee -a $LOGS_FILE

if [ $USERID -ne 0 ]; then
   echo "error::please run this script with root previlage"
   exit 1
fi   

VALIDATE() { 
if [ $1 -ne 0 ]; then
   echo -e "error:: $2  $R failure $N" | tee -a $LOGS_FILE
   exit 1
else
   echo -e " $2 is $G success $N" | tee -a $LOGS_FILE
fi   
}

cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOGS_FILE
VALIDATE $? "adding mongo repo"

dnf install mongodb-org -y &>>$LOGS_FILE
VALIDATE $? "installing mongodb"

systemctl enable mongod &>>$LOGS_FILE
VALIDATE $? "enabling mongodb"

systemctl start mongod &>>$LOGS_FILE
VALIDATE $? "starting mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "allowing remote connections to monogdb"

