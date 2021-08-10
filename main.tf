
#################################################### PROVIDERS ####################################################

provider "aws" {
  #access_key = var.aws_access_key
  #secret_key = var.aws_secret_key
  profile = "terraform"
  region     = var.region
}


#################################################### DATA ####################################################

data "aws_availability_zones" "az" {}

data "aws_ami" "Tomcat" {
  owners           = ["self"]

  filter {
    name   = "name"
    values = ["Tomcat"]
  }
}

data "aws_codestarconnections_connection" "Encora-Tomcat" {
  arn = aws_codestarconnections_connection.Encora-Tomcat.arn
}
#################################################### Resources ####################################################

# SNS #
resource "aws_sns_topic" "Encora-SNS" {
  name = "Encora-SNS"
}

resource "aws_sns_topic_subscription" "Encora-Notifications" {
  topic_arn = "arn:aws:sns:us-east-1:372880842606:Encora-Notifications:c057c20f-6ba0-462a-a692-0a5f9bae6209"
  protocol  = "EMAIL"
  endpoint  = "gauravkardam94@gmail.com"
}

# S3 Artifact Bucket #
resource "aws_s3_bucket" "Encora-Artifacts" {
  bucket = "Encora-Artifacts"
}

resource "aws_s3_bucket_policy" "Encora-Codepipeline-S3-Bucket-Policy" {
  bucket = aws_s3_bucket.Encora-Artifacts.id

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Id": "SSEAndSSLPolicy",
    "Statement": [
        {
            "Sid": "DenyUnEncryptedObjectUploads",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::Encora-Artifacts/*",
            "Condition": {
                "StringNotEquals": {
                    "s3:x-amz-server-side-encryption": "aws:kms"
                }
            }
        },
        {
            "Sid": "DenyInsecureConnections",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::Encora-Artifacts/*",
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
EOF
}


resource "aws_cloudwatch_log_group" "Encora-Logs" {
  name = "Encora-Logs"
}