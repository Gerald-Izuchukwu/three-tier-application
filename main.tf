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
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.env_prefix}_nat_gateway"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "${var.env_prefix}_eip_nat"
  }
}

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
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

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
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
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

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
    Name = "05. Database Server Security Group"
  }
}



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

# Application Tier
resource "aws_launch_template" "logic_app_template" {
  image_id               = var.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.appserverSG.id]
  user_data              = filebase64("backend_script.sh")
  key_name               = aws_key_pair.this.key_name // create a diff keypair
  iam_instance_profile {
    arn = var.S3ReadAndSSManagerProfile
  }

  tags = {
    Name = "${var.env_prefix}_logic_app_template"
  }

}


resource "aws_lb" "internalLoadBalancer" {
  name               = "Internal-Load-Balancer"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internalLoadBalancerSG.id]
  subnets            = [for subnet in aws_subnet.private : subnet.id]

}

resource "aws_ssm_parameter" "alb_dns_name" {
  name  = "/myapp/alb_dns_name"
  type  = "String"
  value = aws_lb.internalLoadBalancer.dns_name
}

resource "aws_lb_listener" "internalLoadBalancer_listener" {
  load_balancer_arn = aws_lb.internalLoadBalancer.arn
  port              = "80"
  protocol          = "HTTP"
  #   ssl_policy        = "ELBSecurityPolicy-2016-08"
  #   certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internalLoadBalancer_tg.arn
  }
}

resource "aws_lb_target_group" "internalLoadBalancer_tg" {
  name     = "backEnd-targetGroup"
  port     = 9662
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health" # Endpoint to check
    interval            = 30        # Time between checks
    port                = 9662
    timeout             = 5 # Time to wait for a response
    healthy_threshold   = 3 # Number of successful checks required to be healthy
    unhealthy_threshold = 3 # Number of failed checks required to be unhealthy
  }
}

resource "aws_autoscaling_group" "logic_app_asg" {
  name     = "logic_app_asg"
  max_size = 1
  min_size = 1

  vpc_zone_identifier = aws_subnet.private[*].id

  launch_template {
    id = aws_launch_template.logic_app_template.id
  }

  target_group_arns = [
    aws_lb_target_group.internalLoadBalancer_tg.arn
  ]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  force_delete              = true

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.env_prefix}_logic_app_instance"
    propagate_at_launch = true
  }
  tag {
    key                 = "Environment"
    value               = var.env_prefix
    propagate_at_launch = true
  }
}

# # resource "aws_autoscaling_policy" "logic_app_asg_scale_down" {
# #   name                   = "scale-down"
# #   scaling_adjustment     = -1
# #   adjustment_type        = "ChangeInCapacity"
# #   cooldown               = 300
# #   autoscaling_group_name = aws_autoscaling_group.logic_app_asg.name
# # }

# # resource "aws_autoscaling_policy" "logic_app_asg_scale_up" {
# #   name                   = "scale-up"
# #   scaling_adjustment     = 1
# #   adjustment_type        = "ChangeInCapacity"
# #   cooldown               = 300
# #   autoscaling_group_name = aws_autoscaling_group.logic_app_asg.name
# # }




## Database Tier

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = aws_subnet.db_private[*].id

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage      = 10
  db_name                = "mydb"
  engine                 = "mysql"
  engine_version         = "8.0.35"
  instance_class         = "db.t3.micro"
  username               = var.db_instance_username
  password               = var.db_instance_password
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.dbserverSG.id]
  availability_zone      = var.avail_zone[0]
}

data "aws_instances" "web_app_asg_instances" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.web_app_asg.name]
  }
}
data "aws_instances" "logic_app_asg_instances" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.logic_app_asg.name]
  }
}

output "externalLoadBalancer_dns" {
  value = aws_lb.externalLoadBalancer.dns_name
}

output "db_instance_dns" {
  value = aws_db_instance.default.endpoint
}


output "web_asg_instance_public_ips" {
  value = data.aws_instances.web_app_asg_instances.public_ips
}

output "logic_asg_instance_public_ips" {
  value = data.aws_instances.logic_app_asg_instances.public_ips
}

output "web_asg_instance_private_ips" {
  value = data.aws_instances.web_app_asg_instances.private_ips
}

output "logic_asg_instance_private_ips" {
  value = data.aws_instances.logic_app_asg_instances.private_ips
}

# # //---after here is nothing


# # # resource "aws_security_group" "appserverSG" {
# # #   name        = "appserverSG"
# # #   description = "Security group for backend app server"
# # #   vpc_id      = aws_vpc.main.id

# # #   ingress {
# # #     description     = "Allow ICMP from web_app_sg"
# # #     from_port       = -1
# # #     to_port         = -1
# # #     protocol        = "icmp"
# # #     security_groups = [aws_security_group.web_app_sg.id]
# # #   }

# # #   ingress {
# # #     description = "Allow ssh only from bastion host"
# # #     from_port   = 22
# # #     to_port     = 22
# # #     protocol    = "tcp"
# # #     cidr_blocks = ["${aws_instance.bastion_host[0].public_ip}/32"]
# # #   }

# # #     ingress {
# # #       description     = "Allow MySQL/Aurora traffic from app server"
# # #       protocol        = "tcp"
# # #       from_port       = 3306
# # #       to_port         = 3306
# # #       security_groups = [aws_security_group.database_sg.id]
# # #     }

# # #     egress {
# # #       protocol        = "tcp"
# # #       from_port       = 3306
# # #       to_port         = 3306
# # #       security_groups = [aws_security_group.database_sg.id]
# # #     }
# # #   ingress {
# # #     description = "Allow ssh from my pc"
# # #     protocol    = "tcp"
# # #     from_port   = 22
# # #     to_port     = 22
# # #     cidr_blocks = [var.my_ip_address]
# # #   }
# # #   ingress {
# # #     from_port       = 80 // http
# # #     to_port         = 80
# # #     protocol        = "tcp"
# # #     security_groups = [aws_security_group.logicapp_alb_sg.id]
# # #   }
# # #   ingress {
# # #     from_port       = 443 // https
# # #     to_port         = 443
# # #     protocol        = "tcp"
# # #     security_groups = [aws_security_group.logicapp_alb_sg.id]
# # #   }
# # #   egress {
# # #     from_port   = 0
# # #     to_port     = 0
# # #     protocol    = "-1"
# # #     cidr_blocks = ["0.0.0.0/0"]
# # #   }
# # #   tags = {
# # #     Name = "web_app_sg"
# # #   }
# # # }