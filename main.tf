provider "aws" {
  region = var.aws_region
profile = "DeveloperAccess-251539659924"

}


data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}


resource "aws_security_group" "nlb_sg" {
  name_prefix = "nlb-sg-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 9440
    to_port     = 9440
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


data "aws_vpc" "selected" {
  id = var.vpc_id
}


resource "aws_lb_target_group" "nlb_tg" {
  name        = "nlb-target-group"
  port        = 9440
  protocol    = "TCP"
  vpc_id      = data.aws_vpc.selected.id
  target_type = "ip"

  health_check {
    protocol            = "HTTPS"
    path = "/console"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }
}


resource "aws_lb_target_group_attachment" "targets" {
  count            = length(var.target_ips)
  target_group_arn = aws_lb_target_group.nlb_tg.arn
  target_id        = var.target_ips[count.index]
  port             = 9440
}


resource "aws_lb" "nlb" {
  name               = "my-nlb"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.nlb_sg.id]
  subnets           = var.subnet_ids
}


resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 9440
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tg.arn
  }
}



#######################
# SECOND NLB (COMMENTED OUT)
#######################

# Uncomment the below code when you want to deploy the second NLB

# Second Target Group
resource "aws_lb_target_group" "nlb_tg_2" {
  name        = "nlb-target-group-for-pc"
  port        = 9440  # Different port to avoid conflicts
  protocol    = "TCP"
  vpc_id      = data.aws_vpc.selected.id
  target_type = "ip"

  health_check {
     protocol            = "HTTPS"
    path = "/console"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }
}

# Attach instances to second Target Group
resource "aws_lb_target_group_attachment" "targets_2" {
  count            = length(var.pc_target_ips)
  target_group_arn = aws_lb_target_group.nlb_tg_2.arn
  target_id        = var.pc_target_ips[count.index]
  port             = 9440  # Use different port for second NLB
}

# Second NLB
resource "aws_lb" "nlb_2" {
  name               = "my-nlb-for-pc"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.nlb_sg.id]
  subnets           = var.subnet_ids
}

# Second NLB Listener
resource "aws_lb_listener" "nlb_listener_2" {
  load_balancer_arn = aws_lb.nlb_2.arn
  port              = 9440  # Different port for second NLB
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tg_2.arn
  }
}


