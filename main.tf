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

# create VPC
resource "aws_vpc" "main" {

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.env_prefix}_vpc"
  }
}


# create subnet
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

# create igw for for vpc
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.env_prefix}_igw"
  }

}

# resource "aws_nat_gateway" "nat" {
#   allocation_id = aws_eip.nat.id
#   subnet_id     = aws_subnet.public[0].id

#   tags = {
#     Name = "${var.env_prefix}_nat_gateway"
#   }
# }

# resource "aws_eip" "nat" {
#   vpc = true
#   tags = {
#     Name = "${var.env_prefix}_eip_nat"
#   }
# }

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  route {
    cidr_block = var.vpc_cidr
    gateway_id = "local"
  }

  tags = {
    Name = "${var.env_prefix}_public_route_table"
  }
}

# associate route table to public subnet
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
  #   route {
  #     cidr_block = "0.0.0.0/0"
  #     gateway_id = aws_nat_gateway
  #   }

  route {
    cidr_block = var.vpc_cidr
    gateway_id = "local"
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




## Web Application Tier

resource "aws_launch_template" "web_app_template" {
  image_id               = var.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web_app_sg.id]
  user_data              = filebase64("public_entry_script.sh")
  key_name               = aws_key_pair.this.key_name


  tags = {
    Name = "${var.env_prefix}_web_app_template"
  }



}
resource "aws_key_pair" "this" {
  key_name   = "${var.env_prefix}_key_pair"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "web_app_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_address]
  }
  ingress {
    from_port   = 80 // http
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


}

resource "aws_autoscaling_group" "web_app_asg" {
  name     = "web_app_asg"
  max_size = 3
  min_size = 2

  vpc_zone_identifier = aws_subnet.public[*].id

  launch_template {
    id = aws_launch_template.web_app_template.id
  }
}

resource "aws_lb" "web_app_lb" {
  name               = "frontEnd-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_app_sg.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

}

resource "aws_lb_listener" "web_app_lb_listener" {
  load_balancer_arn = aws_lb.web_app_lb.arn
  port              = "80"
  protocol          = "HTTP"
  #   ssl_policy        = "ELBSecurityPolicy-2016-08"
  #   certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_app_lb_tg.arn
  }
}


resource "aws_lb_target_group" "web_app_lb_tg" {
  name     = "frontEnd-targetGroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}



## Application Tier
resource "aws_launch_template" "logic_app_template" {
  image_id               = var.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.logic_app_sg.id]
  user_data              = filebase64("private_entry_script.sh")
  key_name               = aws_key_pair.this.key_name


  tags = {
    Name = "${var.env_prefix}_logic_app_template"
  }



}


resource "aws_security_group" "logic_app_sg" {
  name        = "logic_app_sg"
  description = "Security group for web server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow ICMP from web_app_sg"
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.web_app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "logic_app_asg" {
  name     = "logic_app_asg"
  max_size = 3
  min_size = 2

  vpc_zone_identifier = aws_subnet.private[*].id

  launch_template {
    id = aws_launch_template.logic_app_template.id
  }
}

resource "aws_lb" "logic_app_lb" {
  name               = "backEnd-loadbalancer"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.logic_app_sg.id]
  subnets            = [for subnet in aws_subnet.private : subnet.id]

}

resource "aws_lb_listener" "logic_app_lb_listener" {
  load_balancer_arn = aws_lb.logic_app_lb.arn
  port              = "80"
  protocol          = "HTTP"
  #   ssl_policy        = "ELBSecurityPolicy-2016-08"
  #   certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.logic_app_lb_tg.arn
  }
}

resource "aws_lb_target_group" "logic_app_lb_tg" {
  name     = "backEnd-targetGroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

