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

# echo "HOST=testdb.chk0cciwykqg.us-east-1.rds.amazonaws.com" | sudo tee -a /etc/environment
# echo "USER=admin" | sudo tee -a /etc/environment
# echo "DATABASE=testdb" | sudo tee -a /etc/environment



# if you dont want to use natgw, you can create the backend instance like a normal instance and install all the required 
# resources and create an AMI  from the instance. then use the created AMI to create the launch template for the backend instances
# if thats the case, reduce the code above to the one below

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash 
# Set NVM environment variables
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 16 
nvm use 16 
cd backend/
npm install
# npm start >> /home/ec2-user/user-data.log 2>&1 
npm start 