# LOAD BALANCER #

resource "aws_lb_target_group" "encora-target-grp" {
  name     = "encora-target-grp"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.encora-vpc.id
}

resource "aws_elb" "encora-alb" {
  name               = "encora-alb"
  availability_zones = ["us-east-1a", "us-east-1b"]
  security_groups = ["encora-sg"]

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

}

# EC2 Autoscaling #
resource "aws_launch_configuration" "encora-config" {
  name          = "encora_config"
  image_id      = data.aws_ami.Tomcat.id
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "encora-asg" {
  name                      = "encora-asg"
  max_size                  = 5
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  launch_configuration      = aws_launch_configuration.encora-config.name
  vpc_zone_identifier       = [aws_subnet.encora-subnet-1.id, aws_subnet.encora-subnet-2.id]
  aws_iam_service_linked_role = AWSServiceRoleForAutoScaling.name

  initial_lifecycle_hook {
    name                 = "encora-asg"
    default_result       = "ABANDON"
    heartbeat_timeout    = 600
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"

    notification_target_arn = "arn:aws:sns:us-east-1:372880842606:TomcatNotifications"
  }

}

resource "aws_autoscaling_attachment" "encora_asg_attach" {
  autoscaling_group_name = aws_autoscaling_group.encora_asg.id
  elb                    = aws_elb.encora-alb.id
}

resource "aws_iam_service_linked_role" "AWSServiceRoleForAutoScaling" {
  aws_service_name = "autoscaling.amazonaws.com"
}