#VPC
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
  count      = 2
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
  # availability_zone       = var.avail_zone[count.index]
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
  map_public_ip_on_launch = true // change to false later

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

# # NAT-GW
# resource "aws_nat_gateway" "nat" {
#   allocation_id = aws_eip.nat.id
#   subnet_id     = aws_subnet.public[0].id

#   tags = {
#     Name = "${var.env_prefix}_nat_gateway"
#   }
# }

# resource "aws_eip" "nat" {
#   domain = "vpc"
#   tags = {
#     Name = "${var.env_prefix}_eip_nat"
#   }
# }

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
    gateway_id = aws_internet_gateway.this.id
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

# resource "aws_route_table_association" "db_private" {
#   count          = 2
#   subnet_id      = aws_subnet.db_private[count.index].id
#   route_table_id = aws_route_table.private_route_table.id
# }