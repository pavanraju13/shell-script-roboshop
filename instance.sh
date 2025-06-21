#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0529dc4ac677bb0be"

Time_stamp=$( date +%Y-%m-%d-%H-%M-%S )
DOMAIN_NAME=clouddevops.life

for instance in $@
do 
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t2.small --security-group-ids sg-0529dc4ac677bb0be --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" --query "Instances[0].InstanceId" --output text)
if [ $instance != "frontend" ]
then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"
else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"
fi
    echo "$instance IP address: $IP"
done