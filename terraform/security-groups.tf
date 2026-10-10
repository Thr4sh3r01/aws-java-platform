# ============================================
# Security Groups encadenados (DT-006)
# ============================================

# SG 1: ALB - Puerto 80 abierto a Internet
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "Security Group para ALB - trafico HTTP desde Internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP desde Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Todo el trafico saliente"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg-alb"
    Project = var.project_name
    Tier    = "load-balancer"
  }
}

# SG 2: Nginx - Puerto 80 solo desde ALB
resource "aws_security_group" "nginx" {
  name        = "${var.project_name}-sg-nginx"
  description = "Security Group para Nginx - solo desde ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP desde ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Todo el trafico saliente"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg-nginx"
    Project = var.project_name
    Tier    = "web"
  }
}

# SG 3: Tomcat - Puerto 8080 solo desde Nginx
resource "aws_security_group" "tomcat" {
  name        = "${var.project_name}-sg-tomcat"
  description = "Security Group para Tomcat - solo desde Nginx"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP desde Nginx"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx.id]
  }

  egress {
    description = "Todo el trafico saliente"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg-tomcat"
    Project = var.project_name
    Tier    = "application"
  }
}

# SG 4: RDS - Puerto 3306 solo desde Tomcat
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-sg-rds"
  description = "Security Group para RDS MySQL - solo desde Tomcat"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL desde Tomcat"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.tomcat.id]
  }

  tags = {
    Name    = "${var.project_name}-sg-rds"
    Project = var.project_name
    Tier    = "database"
  }
}
