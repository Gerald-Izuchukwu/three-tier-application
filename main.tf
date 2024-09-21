provider "aws" {
  region = "us-east-1"
}

variable "env_prefix" {}
variable "avail_zone" {}
variable "vpc_cidr" {}
variable "my_ip_address" {}
variable "public_key_path" {
  description = "Path to the ssh public key file"
  type        = string
}
variable "private_key_path" {}
variable "instance_type" {}
variable "image_id" {}
variable "db_instance_password" {}
variable "db_instance_username" {}
variable "S3ReadAndSSManagerProfile" {}

# VPC
resource "aws_vpc" "main" {

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.env_prefix}_vpc"
  }
}

# SUBNETS
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.avail_zone[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env_prefix}_public_subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 2)
  availability_zone       = var.avail_zone[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.env_prefix}_private_subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "db_private" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 4)
  availability_zone       = var.avail_zone[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.env_prefix}_db_private_subnet-${count.index + 1}"
  }
}

# IGW
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.env_prefix}_igw"
  }

}

# NAT-GW
# # resource "aws_nat_gateway" "nat" {
# #   allocation_id = aws_eip.nat.id
# #   subnet_id     = aws_subnet.public[0].id

# #   tags = {
# #     Name = "${var.env_prefix}_nat_gateway"
# #   }
# # }

# # resource "aws_eip" "nat" {
# #   vpc = true
# #   tags = {
# #     Name = "${var.env_prefix}_eip_nat"
# #   }
# # }

# ROUTE TABLES
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }


  tags = {
    Name = "${var.env_prefix}_public_route_table"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
  #     route {
  #       cidr_block = "0.0.0.0/0"
  #       gateway_id = aws_nat_gateway.nat.id
  #     }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  #   route {
  #     cidr_block = var.vpc_cidr
  #     gateway_id = "local"
  #   }

  tags = {
    Name = "${var.env_prefix}_private_route_table"
  }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "db_private" {
  count          = 2
  subnet_id      = aws_subnet.db_private[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

# resource "aws_instance" "bastion_host" {
#   count                       = 1
#   ami                         = "ami-0b72821e2f351e396"
#   instance_type               = "t2.micro"
#   key_name                    = aws_key_pair.this.key_name
#   availability_zone           = var.avail_zone[0]
#   subnet_id                   = aws_subnet.public[0].id
#   associate_public_ip_address = true
#   vpc_security_group_ids      = [aws_security_group.bastion_security_group.id]

#   tags = {
#     Name = "${var.env_prefix}_bastion_host"
#   }
# }

# SECURITY GROUPS
resource "aws_security_group" "externalLoadBalancerSG" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_address]
  }

  ingress {
    from_port   = 443 // https
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_address]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "01. External LoadBalancer Security Group"
  }

}

resource "aws_security_group" "webserverSG" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.externalLoadBalancerSG.id]

  }
    ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "02. Web Server Security Group"
  }
}

resource "aws_security_group" "internalLoadBalancerSG" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.webserverSG.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "03. Internal Load Balancer Security Group"
  }
}

resource "aws_security_group" "appserverSG" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 9662
    to_port         = 9662
    protocol        = "tcp"
    security_groups = [aws_security_group.internalLoadBalancerSG.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "04. App Server Security Group"
  }
}

resource "aws_security_group" "dbserverSG" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.appserverSG.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "04. Database Server Security Group"
  }
}

# resource "aws_security_group" "bastion_security_group" {
#   vpc_id = aws_vpc.main.id
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = [var.my_ip_address]
#   }
#   egress { // for traffic to leave the intsnace regardless of protocol and ports
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "bastion-sg"
#   }
# }

#  WEB APPLICATION TIER
resource "aws_launch_template" "web_app_template" {
  image_id               = var.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.webserverSG.id]
  user_data              = filebase64("frontend_script.sh")
  key_name               = aws_key_pair.this.key_name
  iam_instance_profile {
    arn = var.S3ReadAndSSManagerProfile
  }


  tags = {
    Name = "${var.env_prefix}_web_app_template"
  }
}
resource "aws_key_pair" "this" {
  key_name   = "${var.env_prefix}_key_pair"
  public_key = file(var.public_key_path)
}

resource "aws_lb" "externalLoadBalancer" {
  name               = "External-Load-Balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.externalLoadBalancerSG.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

}

resource "aws_lb_listener" "externalLoadBalancer_listener" {
  load_balancer_arn = aws_lb.externalLoadBalancer.arn
  port              = "80"
  protocol          = "HTTP"
  #   ssl_policy        = "ELBSecurityPolicy-2016-08"
  #   certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.externalLoadBalancerTG.arn
  }
}

resource "aws_lb_target_group" "externalLoadBalancerTG" {
  name     = "frontEnd-targetGroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health" # Endpoint to check
    interval            = 30        # Time between checks
    port                = 80
    timeout             = 5 # Time to wait for a response
    healthy_threshold   = 3 # Number of successful checks required to be healthy
    unhealthy_threshold = 3 # Number of failed checks required to be unhealthy
  }
}


resource "aws_autoscaling_group" "web_app_asg" {
  name     = "web_app_asg"
  max_size = 1
  min_size = 1

  vpc_zone_identifier = aws_subnet.public[*].id

  launch_template {
    id = aws_launch_template.web_app_template.id
  }
  target_group_arns = [
    aws_lb_target_group.externalLoadBalancerTG.arn
  ]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  force_delete              = true

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.env_prefix}_web_app_instance"
    propagate_at_launch = true
  }
  tag {
    key                 = "Environment"
    value               = var.env_prefix
    propagate_at_launch = true
  }

}
# resource "aws_autoscaling_policy" "web_app_asg_scale_up" {
#   name                   = "scale-up"
#   scaling_adjustment     = 1
#   adjustment_type        = "ChangeInCapacity"
#   cooldown               = 300
#   autoscaling_group_name = aws_autoscaling_group.web_app_asg.name
# }

# resource "aws_autoscaling_policy" "web_app_asg_scale_down" {
#   name                   = "scale-down"
#   scaling_adjustment     = -1
#   adjustment_type        = "ChangeInCapacity"
#   cooldown               = 300
#   autoscaling_group_name = aws_autoscaling_group.web_app_asg.name
# }
