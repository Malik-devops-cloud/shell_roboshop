#!/bin/bash

USERID=$(id -u)


R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
MONGODB_HOST="mongodb.devsql.store"
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

dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "disabling nodejs"

dnf module enable nodejs -y
VALIDATE $? "enabling nodejs:20" &>>$LOGS_FILE

dnf  install nodejs -y &>>$LOGS_FILE
VALIDATE $? "installing nodejs"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
VALIDATE $? "creating system user"

mkdir /app &>>$LOGS_FILE
VALIADATE $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOGS_FILE
VALIDATE $? "downling catalogue application"

cd /app &>>$LOGS_FILE
VALIATE $? "changing to app directory"

unzip /tmp/catalogue.zip &>>$LOGS_FILE
VALIDATE $? "unzip catalogue"

cd /app 
npm install &>>$LOGS_FILE
VALIDATE $? "install dependencies"

cp catalogue.service /etc/systemd/system/catalogue.service &>>$LOGS_FILE
VALIDATE $? "copy catalogue.service"
systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "daemon-reload"
systemctl enable catalogue &>>$LOGS_FILE
VALIDATE $? "enable catalogue"
systemctl start catalogue &>>$LOGS_FILE
VALIDATE $? "start catalogue"

cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOGS_FILE
VALIDATE $? "copy mongo repo"
dnf install mongodb-mongosh -y &>>$LOGS_FILE
VALIDATE $? "install mongo repo"
mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOGS_FILE
VALIDATE $? "validate catalogue products" 
systemctl restart catalogue &>>$LOGS_FILE
VALIDATE $? "restart catalogue"