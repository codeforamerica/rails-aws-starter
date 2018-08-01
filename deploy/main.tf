terraform {
  backend "s3" {
    bucket = "rails-aws-starter"
    region = "us-east-1"
    key = "state.tf"
  }
}

variable "access_key" {}
variable "secret_key" {}
variable "rds_password" {}
variable "rails_secret_key_base" {}

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
    namespace = "aws:autoscaling:launchconfiguration"
    name = "InstanceType"
    value = "t2.small"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "SECRET_KEY_BASE"
    value = "${var.rails_secret_key_base}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "DATABASE_URL"
    value = "postgresql://${aws_db_instance.db.username}:${var.rds_password}@${aws_db_instance.db.endpoint}/${aws_db_instance.db.name}"
  }
}

resource "aws_db_instance" "db" {
  allocated_storage = 10
  engine = "postgres"
  instance_class = "db.m3.medium"
  kms_key_id = "${aws_kms_key.k.arn}"
  name = "rails_aws_starter"
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
