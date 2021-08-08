
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
  acl    = "private"
}


resource "aws_cloudwatch_log_group" "Encora-Logs" {
  name = "Encora-Logs"
}