provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_security_group" "flask_lab_sg" {
  name = "flask-alb-lab-sg"

  ingress {
    description = "Allow secure terminal over SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "flask_template" {
  name_prefix   = "flask-template"
  image_id      = "ami-02c7683e4ca3ebf58"
  instance_type = "t2.micro"

  key_name = "postgres-lab-key"

  vpc_security_group_ids = [
    aws_security_group.flask_lab_sg.id
  ]

  user_data = base64encode(file("user-data.sh"))
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_lb_target_group" "flask_tg" {
  name     = "flask-target-group"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path = "/"
    port = "5000"
  }
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_lb" "flask_alb" {
  name               = "flask-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.flask_lab_sg.id
  ]

  subnets = data.aws_subnets.default.ids
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.flask_alb.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask_tg.arn
  }
}

resource "aws_autoscaling_group" "flask_asg" {
  name = "flask-asg"

  desired_capacity = 2
  min_size         = 2
  max_size         = 4

  vpc_zone_identifier = data.aws_subnets.default.ids

  target_group_arns = [
    aws_lb_target_group.flask_tg.arn
  ]

  launch_template {
    id      = aws_launch_template.flask_template.id
    version = "$Latest"
  }

  health_check_type = "ELB"
}

output "alb_dns_name" {
  value = aws_lb.flask_alb.dns_name
}