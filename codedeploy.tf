# CodeDeploy #

resource "aws_iam_role" "CodeDeployASGRole" {
  name = "CodeDeployASGRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.CodeDeployASGRole.name
}

resource "aws_codedeploy_app" "Encora-Deploy" {
  name = "Encora-Deploy"
}

resource "aws_codedeploy_deployment_config" "Encora-Deploy-Config" {
  deployment_config_name = "Encora-Deploy-Config"

  minimum_healthy_hosts {
    type  = "HOST_COUNT"
    value = 2
  }
}

resource "aws_codedeploy_deployment_group" "Encora-Deploy-Group" {
  app_name              = aws_codedeploy_app.Encora-Deploy.name
  deployment_group_name = "Encora-Deploy-Group"
  service_role_arn      = aws_iam_role.CodeDeployASGRole.arn
  COPY_AUTO_SCALING_GROUP = aws_autoscaling_group.encora-asg.name

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  load_balancer_info {
    elb_info {
      name = aws_elb.encora-alb.name
    }
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = "STOP_DEPLOYMENT"
      wait_time_in_minutes = 60
    }

    green_fleet_provisioning_option {
      action = "DISCOVER_EXISTING"
    }

    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
    }
  }
}
