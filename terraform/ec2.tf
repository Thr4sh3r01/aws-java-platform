# ============================================
# EC2 con Tomcat y la app Java
# ============================================

# ============================================
# AMI más reciente de Amazon Linux 2023
# ============================================
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ============================================
# IAM Role para Session Manager (SSM)
# ============================================
resource "aws_iam_role" "ssm" {
  name = "${var.project_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "${var.project_name}-ssm-profile"
  role = aws_iam_role.ssm.name
}

# Security Group para EC2 (solo permite SSH y puerto 8080 desde sg-nginx)
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-sg-ec2"
  description = "Security Group para EC2 Tomcat - solo desde Nginx y SSH"
  vpc_id      = aws_vpc.main.id

  # Puerto 8080 (Tomcat) solo desde Nginx
  ingress {
    description     = "HTTP Tomcat desde Nginx"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx.id]
  }

  # Puerto 80 (para balanceo futuro) solo desde ALB
  ingress {
    description     = "HTTP ALB desde ALB"
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
    Name    = "${var.project_name}-sg-ec2"
    Project = var.project_name
    Tier    = "compute"
  }
}

# Instancia EC2
resource "aws_instance" "tomcat" {
  ami                    = data.aws_ami.amazon_linux_2023.id # O usa una AMI propia
  instance_type          = var.ec2_instance_type
  vpc_security_group_ids = [aws_security_group.ec2.id]
  subnet_id              = aws_subnet.public[0].id # Subred pública
  iam_instance_profile   = aws_iam_instance_profile.ssm.name

  # User data: instala Tomcat y despliega la app
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y java-17-amazon-corretto-headless
              cd /opt
              wget https://downloads.apache.org/tomcat/tomcat-9/v9.0.122/apache-tomcat-9.0.122.tar.gz
              tar -xzf apache-tomcat-9.0.122.tar.gz
              mv apache-tomcat-9.0.122 tomcat
              mkdir -p /opt/tomcat/webapps/ROOT
              echo "<!DOCTYPE html><html><body><h1>App Java - Amazon Linux 2023</h1></body></html>" > /opt/tomcat/webapps/ROOT/index.html
              nohup /opt/tomcat/bin/startup.sh &
              EOF

  tags = {
    Name    = "${var.project_name}-tomcat"
    Project = var.project_name
  }
}
