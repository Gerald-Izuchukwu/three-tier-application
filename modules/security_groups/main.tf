# SECURITY GROUPS
resource "aws_security_group" "externalLoadBalancerSG" {
  vpc_id = var.vpc_id 
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
  vpc_id = var.vpc_id  
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
  vpc_id = var.vpc_id  
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
  vpc_id = var.vpc_id  

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
  vpc_id = var.vpc_id  

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