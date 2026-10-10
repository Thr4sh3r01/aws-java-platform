# ============================================
# EC2 con Tomcat y la app Java
# ============================================

# ============================================
# AMI más reciente de Amazon Linux 2
# ============================================
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Par de claves SSH para acceder a la instancia (crea una en consola antes)
resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-ssh-key"
  public_key = file("C:/Users/Josel/.ssh/id_rsa.pub") # Asumiendo que ya tienes una clave
}

# Security Group para EC2 (solo permite SSH y puerto 8080 desde sg-nginx)
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-sg-ec2"
  description = "Security Group para EC2 Tomcat - solo desde Nginx y SSH"
  vpc_id      = aws_vpc.main.id

  # SSH desde anywhere (0.0.0.0/0) - necesario para administración
  ingress {
    description = "SSH desde Internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
  ami                    = data.aws_ami.amazon_linux_2.id # O usa una AMI propia
  instance_type          = var.ec2_instance_type
  key_name               = aws_key_pair.main.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  subnet_id              = aws_subnet.public[0].id # Subred pública

  # User data: instala Tomcat y despliega la app
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y java-1.8.0-openjdk
              cd /opt
              wget https://downloads.apache.org/tomcat/tomcat-9/v9.0.63/apache-tomcat-9.0.63.tar.gz
              tar -xzf apache-tomcat-9.0.63.tar.gz
              mv apache-tomcat-9.0.63 tomcat
              mkdir -p /opt/tomcat/webapps/ROOT
              # Copia el WAR desde la compilación local (o descárgalo después)
              # cp /ruta/a/dptweb-1.0.war /opt/tomcat/webapps/ROOT/
              echo "<!DOCTYPE html><html><body><h1>App Java Deployed</h1></body></html>" > /opt/tomcat/webapps/ROOT/index.html
              nohup /opt/tomcat/bin/startup.sh &
              EOF

  tags = {
    Name    = "${var.project_name}-tomcat"
    Project = var.project_name
  }
}
