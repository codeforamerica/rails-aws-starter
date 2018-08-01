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

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_security_group" "rds" {
  name = "rds_security"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = ["${aws_security_group.application.id}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_security_group" "application" {
  name = "application"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = ["${aws_security_group.load_balancer.id}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_security_group" "load_balancer" {
  name = "load_balancer"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_elastic_beanstalk_application" "beanstalk_app" {
  name = "rails-aws-starter"
}

resource "aws_elastic_beanstalk_environment" "beanstalk_env" {
  name = "rails-aws-starter-sandbox"
  application = "${aws_elastic_beanstalk_application.beanstalk_app.name}"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.8.1 running Ruby 2.5 (Puma)"

  # Minimum size to install gems with native extensions (e.g. Nokogiri)
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

  setting {
    namespace = "aws:ec2:vpc"
    name = "VPCId"
    value = "${aws_vpc.default.id}"
  }

  setting {
    namespace = "aws:elb:loadbalancer"
    name = "SecurityGroups"
    value = "${aws_security_group.load_balancer.id}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "SecurityGroups"
    value = "${aws_security_group.application.id}"
  }
}

resource "aws_subnet" "rds" {
  vpc_id     = "${aws_vpc.default.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1c"

  tags {
    Name = "RDS"
  }
}

resource "aws_subnet" "rds_2" {
  vpc_id     = "${aws_vpc.default.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags {
    Name = "RDS 2"
  }
}

resource "aws_db_subnet_group" "rds" {
  name = "rds"
  subnet_ids = [
    "${aws_subnet.rds.id}",
    "${aws_subnet.rds_2.id}",
  ]

  tags {
    Name = "DB subnet group"
  }
}

resource "aws_db_instance" "db" {
  allocated_storage = 10
  engine = "postgres"
  availability_zone = "us-east-1c"
  instance_class = "db.m3.medium"
  kms_key_id = "${aws_kms_key.k.arn}"
  name = "rails_aws_starter"
  username = "juliebanana"
  password = "${var.rds_password}"
  storage_encrypted = true
  storage_type = "gp2"
  vpc_security_group_ids = ["${aws_security_group.rds.id}"]
  db_subnet_group_name = "${aws_db_subnet_group.rds.name}"
}

resource "aws_kms_key" "k" {
  description = "database encryption key"
}

resource "aws_kms_alias" "k" {
  name = "alias/rails_aws_starter"
  target_key_id = "${aws_kms_key.k.key_id}"
}
