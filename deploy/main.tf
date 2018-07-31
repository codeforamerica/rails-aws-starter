terraform {
  backend "s3" {
    bucket = "rails-aws-starter"
    region = "us-east-1"
    key = "state.tf"
  }
}

variable "access_key" {}
variable "secret_key" {}
variable "rds_username" {}
variable "rds_password" {}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "us-east-1"
}

resource "aws_elastic_beanstalk_application" "beanstalk_app" {
  name = "rails-aws-starter"
}

resource "aws_elastic_beanstalk_environment" "beanstalk_env" {
  name = "rails-aws-starter-sandbox"
  application = "${aws_elastic_beanstalk_application.beanstalk_app.name}"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.8.1 running Ruby 2.5 (Puma)"

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "RDS_HOST"
    value = "${aws_db_instance.db.address}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "RDS_USERNAME"
    value = "${var.rds_username}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "RDS_PASSWORD"
    value = "${var.rds_password}"
  }
}

resource "aws_db_instance" "db" {
  allocated_storage = 10
  engine = "postgres"
  instance_class = "db.m3.medium"
  kms_key_id = "${aws_kms_key.k.arn}"
  name = "rails_aws_starter"
  username = "${var.rds_username}"
  password = "${var.rds_password}"
  storage_encrypted = true
  storage_type = "gp2"
}

resource "aws_kms_key" "k" {
  description = "database encryption key"
}

resource "aws_kms_alias" "k" {
  name = "alias/rails_aws_starter"
  target_key_id = "${aws_kms_key.k.key_id}"
}
