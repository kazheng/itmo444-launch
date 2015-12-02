#!/bin/bash
#Kevin Zheng
#ITMO444 Fall 2015
#AWS Launch Setup Script

#REMOVE THIS!
./../itmo444/cleanup.sh

#InstanceIds will be stored in this array
declare -a instanceArray

#Runs command to create instances and also parses out the InstanceIds
mapfile -t instanceArray < <(aws ec2 run-instances --image-id $1 --count $2 --instance-type $3 --key-name $6 --security-group-ids $4 --subnet-id $5 --iam-instance-profile Name=$7 --associate-public-ip --user-data file://../itmo444-env/install-env.sh --output table | grep InstanceId | sed "s/|//g" | tr -d ' ' | sed "s/InstanceId//g")

#Display InstanceIds
echo "Here are the InstanceIds: "
echo ${instanceArray[@]}

aws ec2 wait instance-running --instance-ids ${instanceArray[@]}

echo "The Instance(s) are now up and running!"

#Create Load Balancer
ELBURL=$(aws elb create-load-balancer --load-balancer-name marvel-elb --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 --security-groups $4 --subnets $5 --output=text)

echo -e "\n" 
echo  $ELBURL

echo -e "\nELB created, now waiting 30 seconds"
for i in {0..30}; do echo -ne '.'; sleep 1; done

#Register Instances with ELM
aws elb register-instances-with-load-balancer --load-balancer-name marvel-elb --instances ${instanceArray[@]}

aws elb configure-health-check --load-balancer-name marvel-elb --health-check Target=HTTP:80/index.html,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3

echo -e "\nWait about 3 minutes before opening ELB in a browser."
for  i in {0..180}; do echo -ne '.'; sleep 1; done

#Creates Launch Configuration

aws autoscaling create-launch-configuration --launch-configuration-name marvel-launch-configuration --image-id $1 --instance-type $3 --key-name $6  --security-groups $4 --user-data file://../itmo444-env/install-env.sh --iam-instance-profile phpDeveloperRole

#Create Autoscaling Group

aws autoscaling create-auto-scaling-group --auto-scaling-group-name marvel-auto-scaling-group --launch-configuration-name marvel-launch-configuration --load-balancer-names marvel-elb  --health-check-type ELB --min-size 3 --max-size 6 --desired-capacity 3 --default-cooldown 600 --health-check-grace-period 120 --vpc-zone-identifier $5


#Create DB
mapfile -t dbInstanceARR < <(aws rds describe-db-instances --output json | grep "\"DBInstanceIdentifier" | sed "s/[\"\:\, ]//g" | sed "s/DBInstanceIdentifier//g" )

if [ ${#dbInstanceARR[@]} -gt 0 ]
   then
   echo "Deleting existing RDS database-instances"
   LENGTH=${#dbInstanceARR[@]}

      for (( i=0; i<${LENGTH}; i++));
      do
      if [ ${dbInstanceARR[i]} == "jrh-db" ]
     then
      echo "db exists"
     else
     aws rds create-db-instance --db-instance-identifier marvel-db --db-instance-class db.t1.micro --engine MySQL --master-username controller --master-user-password ilovebunnies --allocated-storage 5
      fi
     done
fi

