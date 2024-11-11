# Application Tier
resource "aws_launch_template" "logic_app_template" {
  image_id               = var.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [var.appserverSG]
  user_data              = filebase64("backend_script.sh")
  key_name               = var.key_name // create a diff keypair OUTPUT
  # key_name               = aws_key_pair.this.key_name // create a diff keypair OUTPUT
  iam_instance_profile {
    arn = var.S3ReadAndSSManagerProfile
  }

  tags = {
    Name = "${var.env_prefix}_logic_app_template"
  }
}


resource "aws_lb" "internalLoadBalancer" {
  name               = "Internal-Load-Balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.internal_lb_sg]                           //OUTPUT
  subnets            = [for subnet in var.private_subnet : subnet.id] //OUTPUT
  # subnets            = [for subnet in aws_subnet.private : subnet.id] //OUTPUT

}

resource "aws_ssm_parameter" "alb_dns_name" {
  name  = "/myapp/alb_dns_name"
  type  = "String"
  value = aws_lb.internalLoadBalancer.dns_name
}

resource "aws_lb_listener" "internalLoadBalancer_listener" {
  load_balancer_arn = aws_lb.internalLoadBalancer.arn
  port              = "80"
  protocol          = "HTTP"
  #   ssl_policy        = "ELBSecurityPolicy-2016-08"
  #   certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internalLoadBalancer_tg.arn
  }
}

resource "aws_lb_target_group" "internalLoadBalancer_tg" {
  name     = "backEnd-targetGroup"
  port     = 9662
  protocol = "HTTP"
  vpc_id   = var.vpc_id //OUTPUT

  health_check {
    path                = "/health" # Endpoint to check
    interval            = 30        # Time between checks
    port                = 9662
    timeout             = 20 # Time to wait for a response
    healthy_threshold   = 3  # Number of successful checks required to be healthy
    unhealthy_threshold = 3  # Number of failed checks required to be unhealthy
  }
}

resource "aws_autoscaling_group" "logic_app_asg" {
  name     = "logic_app_asg"
  max_size = 2
  min_size = 2

  # vpc_zone_identifier = aws_subnet.private[*].id //OUTPUT
  vpc_zone_identifier = [var.private_subnet[0].id, var.private_subnet[1].id] //OUTPUT


  launch_template {
    id = aws_launch_template.logic_app_template.id
  }

  target_group_arns = [
    aws_lb_target_group.internalLoadBalancer_tg.arn
  ]
  health_check_type         = "EC2"
  health_check_grace_period = 600
  force_delete              = true

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.env_prefix}_logic_app_instance"
    propagate_at_launch = true
  }
  tag {
    key                 = "Environment"
    value               = var.env_prefix
    propagate_at_launch = true
  }
}

# # # resource "aws_autoscaling_policy" "logic_app_asg_scale_down" {
# # #   name                   = "scale-down"
# # #   scaling_adjustment     = -1
# # #   adjustment_type        = "ChangeInCapacity"
# # #   cooldown               = 300
# # #   autoscaling_group_name = aws_autoscaling_group.logic_app_asg.name
# # # }

# # # resource "aws_autoscaling_policy" "logic_app_asg_scale_up" {
# # #   name                   = "scale-up"
# # #   scaling_adjustment     = 1
# # #   adjustment_type        = "ChangeInCapacity"
# # #   cooldown               = 300
# # #   autoscaling_group_name = aws_autoscaling_group.logic_app_asg.name
# # # }
