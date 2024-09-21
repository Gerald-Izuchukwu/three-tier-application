#!/bin/bash


# Update and install Docker
sudo yum update -y >> /var/log/user-data.log 2>&1
sudo yum install -y docker >> /var/log/user-data.log 2>&1

# Start Docker service
sudo systemctl start docker >> /var/log/user-data.log 2>&1

while ! systemctl is-active docker; do sleep 5; done
# Set environment variables
export AWS_REGION='us-east-1'
export REPOSITORY_NAME='cross_a'
export IMAGE_TAG='latest'
export REPOSITORY_ID='u0i6l9j2'

# Check if required environment variables are set
if [ -z "$AWS_REGION" ] || [ -z "$REPOSITORY_NAME" ] || [ -z "$IMAGE_TAG" ] || [ -z "$REPOSITORY_ID" ]; then
  echo "Error: Required environment variables (AWS_REGION, REPOSITORY_NAME, IMAGE_TAG) are not set." >> /var/log/user-data.log
  exit 1
fi

# Pull the image from ECR
sudo docker pull public.ecr.aws/$REPOSITORY_ID/$REPOSITORY_NAME:$IMAGE_TAG >> /var/log/user-data.log 2>&1
echo "Image pulled successfully!" >> /var/log/user-data.log

# Optionally create a Docker network
sudo docker network create mynetwork >> /var/log/user-data.log 2>&1

# Run the Docker container
sudo docker run -d -p 9661:9661 --network mynetwork --name crossa public.ecr.aws/$REPOSITORY_ID/$REPOSITORY_NAME:$IMAGE_TAG >> /var/log/user-data.log 2>&1
echo "Running image" >> /var/log/user-data.log












# sudo yum update -y

# sudo yum install -y docker

# sudo systemctl start docker

# sudo usermod -aG docker $USER

# export AWS_REGION='us-east-1'

# export REPOSITORY_NAME='cross_a'

# export IMAGE_TAG='latest'

# export REPOSITORY_ID='u0i6l9j2'

# # Check if required environment variables are set
# if [ -z "$AWS_REGION" ] || [ -z "$REPOSITORY_NAME" ] || [ -z "$IMAGE_TAG" ] || [ -z "$REPOSITORY_ID" ]; then
#   echo "Error: Required environment variables (AWS_REGION, AWS_ACCOUNT_ID, REPOSITORY_NAME, IMAGE_TAG) are not set."
#   exit 1
# fi

# # Pull the image from ECR
# sudo docker pull public.ecr.aws/$REPOSITORY_ID/$REPOSITORY_NAME:$IMAGE_TAG

# echo "Image pulled successfully!"

# sudo docker network create mynetwork

# sudo docker run -d -p 9661:9661 --network mynetwork --name crossa $REPOSITORY_NAME:1 #chnage the -ne to --net

# echo "Running image"

