
# --- VPC & Internet Gateway ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = { Name = "main-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "main-igw" }
}

# --- NAT Gateway Setup ---
# 1. Create a Static Public IP (EIP)
resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw] 
  tags       = { Name = "nat-gateway-eip" }
}

# 2. Create the NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id 
  tags          = { Name = "main-nat-gateway" }

 
  depends_on = [aws_internet_gateway.igw]
}

# --- Subnets ---
data "aws_availability_zones" "available" {
  state = "available"
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
   Name                               = "public-subnet"
  "kubernetes.io/role/elb"           = "1"           
  "kubernetes.io/cluster/main-cluster" = "shared"
}
}

# Private Frontend
resource "aws_subnet" "frontend" {
  count             = length(var.frontend_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.frontend_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
  Name                               = "private-subnet-frontend"
  "kubernetes.io/role/internal-elb"  = "1"            
  "kubernetes.io/cluster/main-cluster" = "shared"
}
}

# Private Backend
resource "aws_subnet" "backend" {
  count             = length(var.backend_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.backend_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
   tags = {
  Name                               = "private-subnet-backend"
  "kubernetes.io/role/internal-elb"  = "1"            
  "kubernetes.io/cluster/main-cluster" = "shared"
}
}

# Private RDS
resource "aws_subnet" "rds" {
  count             = length(var.rds_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.rds_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = { Name = "private-rds-${count.index + 1}" }
}
# --- Route Tables ---
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

# --- Route Table Associations ---
resource "aws_route_table_association" "public_assoc" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "frontend_assoc" {
  count          = length(var.frontend_subnet_cidrs)
  subnet_id      = aws_subnet.frontend[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "backend_assoc" {
  count          = length(var.backend_subnet_cidrs)
  subnet_id      = aws_subnet.backend[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "rds_assoc" {
  count          = length(var.rds_subnet_cidrs)
  subnet_id      = aws_subnet.rds[count.index].id
  route_table_id = aws_route_table.private_rt.id
}