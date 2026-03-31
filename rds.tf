# --- 1. DB Subnet Group ---
resource "aws_db_subnet_group" "main" {
  name       = "main-rds-subnet-group"
  subnet_ids = aws_subnet.rds[*].id
  tags       = { Name = "main-rds-subnet-group" }
}

# --- 2. Security Group for RDS ---
resource "aws_security_group" "rds_sg" {
  name   = "rds-security-group"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_eks_cluster.main.vpc_config[0].cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- 3. RDS MySQL Instance ---
resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  max_allocated_storage  = 100 # Allows storage to auto-scale if needed
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro" # Free tier eligible/Cost effective
  db_name                = "webappdb"
  username               = "admin"
  password               = var.db_password 
  
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  
  multi_az               = true           # High availability across 2 AZs
  skip_final_snapshot    = true           # Set to false for production
  publicly_accessible    = false
  
  storage_type           = "gp3"
  backup_retention_period = 7
}