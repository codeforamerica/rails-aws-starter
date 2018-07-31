terraform {
  backend "s3" {
    bucket = "rails-aws-starter"
    region = "us-east-1"
    key = "state.tf"
    # IAM User with read/write permissions for S3 bucket
    access_key =
    secret_key =
  }
}

# IAM User with EB deploy permissions
provider "aws" {
  access_key =
  secret_key =
  region = "us-east-1"
}

resource "aws_elastic_beanstalk_application" "beanstalk_app" {
  name = "rails-aws-starter"
}

resource "aws_elastic_beanstalk_environment" "beanstalk_env" {
  name = "rails-aws-starter-development"
  application = "${aws_elastic_beanstalk_application.beanstalk_app.name}"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.8.1 running Ruby 2.5 (Puma)"
}