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

# Codedeploy Instance Role #

resource "aws_iam_role" "CodeDeploy-EC2-Instance-Profile" {
  name = "CodeDeploy-EC2-Instance-Profile"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codedeploy.amazonaws.com",
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
    ]
  })
}

resource "aws_iam_policy" "CodeDeploy-EC2-Permissions" {
  name = "CodeDeploy-EC2-Permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:Get*",
          "s3:List*"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::Encora-Artifacts/*",
          "arn:aws:s3:::aws-codedeploy-us-east-1/*"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "CodeDeploy-EC2-PolicyAttach" {
  role       = aws_iam_role.CodeDeploy-EC2-Instance-Profile.name
  policy_arn = aws_iam_policy.CodeDeploy-EC2-Permissions.arn
}

# EC2 Autoscaling #
resource "aws_launch_configuration" "encora-config" {
  name          = "encora_config"
  image_id      = data.aws_ami.Tomcat.id
  instance_type = "t2.micro"
  iam_instance_profile = "CodeDeploy-EC2-Instance-Profile"
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo service codedeploy-agent restart
              /usr/java/apache-tomcat-8.5.69/bin/startup.sh
              EOF
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