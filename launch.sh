#!/bin/bash

aws ec2 run-instances --image-id $1 --count $2 --instance-type $3 --key-name $6 --security-group-ids $4 --subnet-id $5  --associate-public-ip --user-data file://../itmo444-env/install-env.sh --debug


echo "$2 AWS $1 Instances of type: $3 in Security Group: $4 in Subnet: $5 with key name: $6 were created."
