
## Database Tier

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [for subnet in var.db_subnet_group : subnet.id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0.35"
  instance_class       = "db.t3.micro"
  username             = var.db_instance_username
  password             = var.db_instance_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.default.name
  #   vpc_security_group_ids = [aws_security_group.dbserverSG.id]
  vpc_security_group_ids = [var.dbserverSG]
  availability_zone      = var.avail_zone[0]
}

