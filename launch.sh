#!/bin/bash

./../itmo444/cleanup.sh

declare -a instanceArray

mapfile -t instanceArray < <(aws ec2 run-instances --image-id $1 --count $2 --instance-type $3 --key-name $6 --security-group-ids $4 --subnet-id $5 --iam-instance-profile Name=$7 --associate-public-ip --user-data file://../itmo444-env/install-env.sh --output table | grep InstanceId | sed "s/|//g" | tr -d ' ' | sed "s/InstanceId//g")

echo "Here are the InstanceIds: "
echo ${instanceArray[@]}

#aws ec2 wait instance-running --instance-ids ${instanceArray[@]}

echo "The Instance(s) are now up and running!"

ELBURL=$(aws elb create-load-balancer --load-balancer-name marvel-elb --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 --security-groups $4 --subnets $5 --output=text)

echo -e "\n" 
echo  $ELBURL

echo -e "\nELB created, now waiting 30 seconds"
for i in {0..30}; do echo -ne '.'; sleep 1; done


