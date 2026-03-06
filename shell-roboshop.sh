#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-022724821f81b310d"

for instance in $@
  do 
  INSTANCE_ID=$(aws ec2 run-instances  --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId'  --output text)
    if [ $instance -ne "frontend" ]; then
      IP=$(aws ec2 describe-instances  --instance-ids $INSTANCE_ID  --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
    else
       IP=$(aws ec2 describe-instances  --instance-ids $INSTANCE_ID  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    fi
    echo "$instance :$IP"
  done  

