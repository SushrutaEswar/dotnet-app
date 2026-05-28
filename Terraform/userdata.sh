#!/bin/bash

yum update -y

yum install ruby wget -y

cd /home/ec2-user

wget https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install

chmod +x ./install

./install auto

systemctl start codedeploy-agent
systemctl enable codedeploy-agent

yum install dotnet-sdk-8.0 -y