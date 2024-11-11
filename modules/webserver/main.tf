#  WEB APPLICATION TIER
resource "aws_launch_template" "web_app_template" {
  image_id               = var.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [var.webserverSG]
  # vpc_security_group_ids = [aws_security_group.webserverSG.id]
  user_data              = filebase64("frontend_script.sh")
  key_name               = aws_key_pair.this.key_name
  iam_instance_profile {
    arn = var.S3ReadAndSSManagerProfile
  }
  tags = {
    Name = "${var.env_prefix}_web_app_template"
  }
}

resource "aws_key_pair" "this" {
  key_name   = "${var.env_prefix}_key_pair"
  public_key = file(var.public_key_path)
}

resource "aws_lb" "externalLoadBalancer" {
  name               = "External-Load-Balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.external_lb_sg] 
  subnets = [var.public_subnet[0].id, var.public_subnet[1].id] //OUTPUT
}

resource "aws_lb_listener" "externalLoadBalancer_listener" {
  load_balancer_arn = aws_lb.externalLoadBalancer.arn
  port              = "80"
  protocol          = "HTTP"
  #   ssl_policy        = "ELBSecurityPolicy-2016-08"
  #   certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.externalLoadBalancerTG.arn
  }
}

resource "aws_lb_target_group" "externalLoadBalancerTG" {
  name     = "frontEnd-targetGroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id //OUTPUT

  health_check {
    path                = "/health" # Endpoint to check
    interval            = 30        # Time between checks
    port                = 80
    timeout             = 20 # Time to wait for a response
    healthy_threshold   = 3  # Number of successful checks required to be healthy
    unhealthy_threshold = 3  # Number of failed checks required to be unhealthy
  }
}

resource "aws_autoscaling_group" "web_app_asg" {
  name     = "web_app_asg"
  max_size = 2
  min_size = 2

#   vpc_zone_identifier = [aws_subnet.public[*].id] //OUTPUT
  vpc_zone_identifier = [var.public_subnet[0].id, var.public_subnet[1].id] //OUTPUT

  launch_template {
    id = aws_launch_template.web_app_template.id
  }
  target_group_arns = [
    aws_lb_target_group.externalLoadBalancerTG.arn
  ]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  force_delete              = true

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.env_prefix}_web_app_instance"
    propagate_at_launch = true
  }
  tag {
    key                 = "Environment"
    value               = var.env_prefix
    propagate_at_launch = true
  }
}

# # resource "aws_autoscaling_policy" "web_app_asg_scale_up" {
# #   name                   = "scale-up"
# #   scaling_adjustment     = 1
# #   adjustment_type        = "ChangeInCapacity"
# #   cooldown               = 300
# #   autoscaling_group_name = aws_autoscaling_group.web_app_asg.name
# # }

# # resource "aws_autoscaling_policy" "web_app_asg_scale_down" {
# #   name                   = "scale-down"
# #   scaling_adjustment     = -1
# #   adjustment_type        = "ChangeInCapacity"
# #   cooldown               = 300
# #   autoscaling_group_name = aws_autoscaling_group.web_app_asg.name
# # }