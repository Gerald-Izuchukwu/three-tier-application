#!/bin/bash

sudo yum update -y

sudo touch app.js

sudo yum install -y docker

sudo systemctl start docker

sudo usermod -aG docker $USER
