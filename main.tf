terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Descobre 2 AZs disponíveis
data "aws_availability_zones" "available" {
  state = "available"
}

########################
# REDE (VPC + Sub-redes)
########################

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ha-webapp-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "ha-webapp-igw"
  }
}

# 2 sub-redes públicas em AZs diferentes
resource "aws_subnet" "public" {
  for_each = {
    a = data.aws_availability_zones.available.names[0]
    b = data.aws_availability_zones.available.names[1]
  }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.key == "a" ? var.public_subnet_a_cidr : var.public_subnet_b_cidr
  map_public_ip_on_launch = true
  availability_zone       = each.value

  tags = {
    Name = "ha-webapp-public-${each.key}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "ha-webapp-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

#####################
# SECURITY GROUPS
#####################

# SG do ALB: abre 80/443 para a Internet
resource "aws_security_group" "alb_sg" {
  name        = "ha-webapp-alb-sg"
  description = "ALB ingress 80/443 from Internet"
  vpc_id      = aws_vpc.this.id

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
    Name = "ha-webapp-alb-sg"
  }
}

# SG das EC2: aceita 80 somente do ALB, SSH opcional do seu IP
resource "aws_security_group" "ec2_sg" {
  name        = "ha-webapp-ec2-sg"
  description = "EC2 ingress from ALB on 80"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  dynamic "ingress" {
    for_each = var.ssh_ingress_cidr == null ? [] : [1]

    content {
      description = "SSH from your IP"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.ssh_ingress_cidr]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ha-webapp-ec2-sg"
  }
}

###########################
# LOAD BALANCER + TARGET
###########################

resource "aws_lb" "alb" {
  name               = "ha-webapp-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for s in aws_subnet.public : s.id]
  idle_timeout       = 60

  tags = {
    Name = "ha-webapp-alb"
  }
}

resource "aws_lb_target_group" "tg" {
  name         = "ha-webapp-tg"
  port         = 80
  protocol     = "HTTP"
  vpc_id       = aws_vpc.this.id
  target_type  = "instance"

  health_check {
    enabled             = true
    path                = "/"
    matcher             = "200-399"
    interval            = 15
    unhealthy_threshold = 3
    healthy_threshold   = 2
    timeout             = 5
  }
}

# Listener HTTP com forward direto para o Target Group
# (se quiser redirect para HTTPS, ajuste conforme necessidade)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Caso tenha um ACM cert válido e queira 443, descomente e preencha var.acm_certificate_arn
# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.alb.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = var.acm_certificate_arn
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.tg.arn
#   }
# }

###########################
# EC2 Launch Template + ASG
###########################

resource "aws_launch_template" "lt" {
  name_prefix   = "ha-webapp-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  update_default_version = true

  network_interfaces {
    security_groups             = [aws_security_group.ec2_sg.id]
    associate_public_ip_address = true
  }

  user_data = base64encode(file("${path.module}/user_data.sh"))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "ha-webapp-ec2"
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  name                      = "ha-webapp-asg"
  min_size                  = var.asg_min
  max_size                  = var.asg_max
  desired_capacity          = var.asg_desired
  vpc_zone_identifier       = [for s in aws_subnet.public : s.id]
  health_check_type         = "EC2"
  health_check_grace_period = 60
  target_group_arns         = [aws_lb_target_group.tg.arn]

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ha-webapp-asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling baseado em CPU (Target Tracking)
resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "cpu-target-50"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.cpu_target
  }
}

###########################
# ROUTE 53 (ALIAS → ALB)
###########################

# Aponta o hostname para o ALB
resource "aws_route53_record" "app_alias" {
  zone_id = var.route53_zone_id
  name    = var.route53_record_name
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = false
  }
}
