# public LB sg
# HTTP / HTTPS
resource "aws_security_group" "public_lb_sg" {
  name        = "public-alb-sg"
  description = "Allow HTTP/HTTPS from anywhere to ALB"
  vpc_id      = aws_vpc.msa_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
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
    Name = "public-lb-sg"
  }
}

# private ALB sg
resource "aws_security_group" "private_lb_sg" {
  name        = "private-lb-sg"
  description = "Allow HTTP/HTTPS from anywhere to ALB"
  vpc_id      = aws_vpc.msa_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.public_lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-lb-sg"
  }
}

# Web sg
# bastion 인스턴스에서 접속하기 위한 정책
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "web-sg"
  vpc_id      = aws_vpc.msa_vpc.id

  ingress {
    description     = "HTTP"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.private_lb_sg.id] 
  }

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

# DB sg
# resource "aws_security_group" "db_sg" {
#   name        = "db-sg"
#   description = "db-sg"
#   vpc_id      = aws_vpc.msa_vpc.id

#   ingress {
#     description     = "db from web"
#     from_port       = 3306
#     to_port         = 3306
#     protocol        = "tcp"
#     security_groups = [aws_security_group.web_sg.id]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "db-sg"
#   }
# }


# bastion sg
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH from trusted IP"
  vpc_id      = aws_vpc.msa_vpc.id

  ingress {
    description = "SSH from Admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["118.218.200.33/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}