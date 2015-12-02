#!/bin/bash

./../itmo444/cleanup.sh

declare -a instanceArray

mapfile -t instanceArray < <(aws ec2 run-instances --image-id $1 --count $2 --instance-type $3 --key-name $6 --security-group-ids $4 --subnet-id $5 --iam-instance-profile Name=$7 --associate-public-ip --user-data file://../itmo444-env/install-env.sh --output table | grep INstanceID | sed "s/|//g" | tr -d ' ' | sed "s/InstanceID//g")

echo ${instanceArray[@]}





