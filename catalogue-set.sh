#!/bin/bash

USERID=$(id -u)

set -euo pipefail #this is the exit if error occurs
trap 'error"there is error in $LINENO,command is :$BASH_COMMAND"' ERR

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
MONGODB_HOST="mongodb.devsql.store"
SCRIPT_DIR=$PWD
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "script executing at: $(date)" | tee -a $LOGS_FILE

if [ $USERID -ne 0 ]; then
   echo "error::please run this script with root previlage"
   exit 1
fi   


dnf module disable nodejs -y &>>$LOGS_FILE
dnf module enable nodejs:20 -y &>>$LOGS_FILE
dnf  install nodejs -y &>>$LOGS_FILE
ech0 -e "nodejs package setup completed ...$G SUCCESS $N"

id roboshop 
if [$? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    
else
    echo -e "user already exists ... $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOGS_FILE
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOGS_FILE
cd /app &>>$LOGS_FILE

rm -rf /app/*
unzip /tmp/catalogue.zip &>>$LOGS_FILE

cd /app 
npm install &>>$LOGS_FILE


cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOGS_FILE
systemctl daemon-reload &>>$LOGS_FILE
systemctl enable catalogue &>>$LOGS_FILE
systemctl start catalogue &>>$LOGS_FILE
echo -e "catalogue started .. $G SUCCESS $N"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOGS_FILE
dnf install mongodb-mongosh -y &>>$LOGS_FILE
echo -e "mongodb installed successfully"

INDEX=$(mongosh mongodb.devsql.store --quiet --eval "db.getMongo().getDBNames().index of ('catalogue')")
if [$INDEX -lt 0 ]; then
   mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOGS_FILE
else
   echo -e "catalogue products already exists ... $Y SKIPPING $N"
fi


systemctl restart catalogue &>>$LOGS_FILE
echo -e "catalog products loaded successfully ... $G success $N"