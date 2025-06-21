#!/bin/bash

RECORD_NAME=$1
IP=$2
instance=$3
ZONE_ID=Z0511103ULD2JWV1IRW1



aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Creating or Updating a record set for cognito endpoint"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$RECORD_NAME'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP'"
            }]
        }
        }]
    }' &> /dev/null
if [ $? -eq 0 ]
then
   echo -e "\e[32mRoute53 record created for $instance successfully\e[0m"
else
   echo -e "\e[31m32mRoute53 record created for $instance failure\e[0m"
fi