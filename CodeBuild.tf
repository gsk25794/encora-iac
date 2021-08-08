# CodeBuild #
resource "aws_iam_role" "CodebuildEncoraTomcatServiceRole" {
  name = "CodebuildEncoraTomcatServiceRole"

  assume_role_policy = <<EOF
    {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "codebuild.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
    }
EOF
}

resource "aws_iam_role_policy" "AWSCodebuildPolicy" {
  role = aws_iam_role.CodebuildEncoraTomcatServiceRole.name

  policy = <<POLICY
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Resource": [
                    "arn:aws:logs:us-east-1:372880842606:log-group:/aws/codebuild/Encora-Build",
                    "arn:aws:logs:us-east-1:372880842606:log-group:/aws/codebuild/Encora-Build:*"
                ],
                "Action": [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ]
            },
            {
                "Effect": "Allow",
                "Resource": [
                    "arn:aws:s3:::codepipeline-us-east-1-*"
                ],
                "Action": [
                    "s3:PutObject",
                    "s3:GetObject",
                    "s3:GetObjectVersion",
                    "s3:GetBucketAcl",
                    "s3:GetBucketLocation"
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "codebuild:CreateReportGroup",
                    "codebuild:CreateReport",
                    "codebuild:UpdateReport",
                    "codebuild:BatchPutTestCases",
                    "codebuild:BatchPutCodeCoverages"
                ],
                "Resource": [
                    "arn:aws:codebuild:us-east-1:372880842606:report-group/Encora-Build-Report-*"
                ]
            },
            {
                "Effect": "Allow",
                "Resource": [
                    "arn:aws:logs:us-east-1:372880842606:log-group:EncoraLogs",
                    "arn:aws:logs:us-east-1:372880842606:log-group:EncoraLogs:*"
                ],
                "Action": [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ]
            }
        ]
    }
}

resource "aws_codebuild_project" "Encora-Build" {
  name          = "Encora-Build"
  description   = "Encora-Build_project"
  build_timeout = "5"
  service_role  = aws_iam_role.CodebuildEncoraTomcatServiceRole.arn

  artifacts {
    type = "S3"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.Encora-Artifacts.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:1.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "Encora-Logs"
      stream_name = "Encora-Logs"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.Encora-Artifacts.id}/build-log"
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/gsk25794/encora.git"
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }
  }

  source_version = "master"

  vpc_config {

    vpc_id = aws_vpc.encora-vpc.id

    subnets = [
      aws_subnet.encora-subnet-1.id,
      aws_subnet.encora-subnet-1.id
    ]

    security_group_ids = [
      aws_security_group.encora-sg.id
    ]
  }
}