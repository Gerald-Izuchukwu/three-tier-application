#!/bin/bash

sudo yum update -y >> /var/log/user-data.log 2>&1
sudo yum install -y docker >> /var/log/user-data.log 2>&1
sudo systemctl start docker >> /var/log/user-data.log 2>&1
while ! systemctl is-active docker; do sleep 5; done
sudo docker run node:20-alpine >> /var/log/user-data.log 2>&1
sudo su -
dnf -y localinstall https://dev.mysql.com/get/mysql80-community-release-el9-4.noarch.rpm >> /var/log/user-data.log 2>&1
dnf -y install mysql mysql-community-client >> /var/log/user-data.log 2>&1

cd /home/ec2-user
sudo aws s3 cp s3://three-tier-test-app/backend/ backend/ --recursive
sudo chown -R ec2-user:ec2-user /home/ec2-user/backend
sudo chmod -R 755 /home/ec2-user/backend
cd backend
touch config.env
echo "HOST=$(aws ssm get-parameter --name "/myapp/db_host" --query "Parameter.Value" --output text)" >> config.env
echo "PASSWORD=$(aws ssm get-parameter --name "/myapp/db_password" --query "Parameter.Value" --output text)" >> config.env
echo "MYSQL_USER=$(aws ssm get-parameter --name "/myapp/db_username" --query "Parameter.Value" --output text)" >> config.env
echo "DATABASE=$(aws ssm get-parameter --name "/myapp/db_name" --query "Parameter.Value" --output text)" >> config.env

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash 
# Set NVM environment variables
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 16 
nvm use 16 
cd backend/
sudo env "PATH=$PATH" npm install
sudo npm install 
# npm start >> /home/ec2-user/user-data.log 2>&1 
npm start 