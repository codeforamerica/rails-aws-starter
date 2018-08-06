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

# Specify the provider and access details
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "us-east-1"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name = "application_vpc"
  }
}

# Create a public subnet for our load balancer
resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1e"
  tags {
    Name = "public"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_route_table" "internet_access" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
}

resource "aws_route_table_association" "subnet_route_table" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.internet_access.id}"
}

resource "aws_network_acl" "default" {
  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = [
    "${aws_subnet.public.id}"
  ]
  egress {
    protocol = "-1"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }

  # Ephemeral ports for response packets
  ingress {
    protocol = "tcp"
    rule_no = 200
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
  }

  # HTTP
  ingress {
    protocol = "tcp"
    rule_no = 300
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port = 80
  }

  # HTTPS
  ingress {
    protocol = "tcp"
    rule_no = 400
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 443
    to_port = 443
  }

  tags {
    Name = "public"
  }
}

# Create a primary private subnet
resource "aws_subnet" "private" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags {
    Name = "private"
  }
}

# Create a second private subnet for RDS fallback
resource "aws_subnet" "private_2" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags {
    Name = "private 2"
  }
}

resource "aws_eip" "eip" {
  vpc = true
  depends_on = [
    "aws_internet_gateway.default"
  ]
}

resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.eip.id}"
  subnet_id = "${aws_subnet.public.id}"

  depends_on = [
    "aws_internet_gateway.default"
  ]

  tags {
    Name = "NAT"
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.gw.id}"
  }
}

resource "aws_route_table_association" "private_route_table" {
  subnet_id = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_network_acl" "private" {
  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = [
    "${aws_subnet.private.id}"
  ]
  egress {
    protocol = "-1"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }

  ingress {
    protocol = "tcp"
    rule_no = 200
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
  }

  ingress {
    protocol = "tcp"
    rule_no = 300
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port = 80
  }
//
//  ingress {
//    protocol = "tcp"
//    rule_no = 400
//    action = "allow"
//    cidr_block = "0.0.0.0/0"
//    from_port = 443
//    to_port = 443
//  }

  tags {
    Name = "private"
  }
}

resource "aws_kms_key" "k" {
  description = "database encryption key"
}

resource "aws_kms_alias" "k" {
  name = "alias/rails_aws_starter"
  target_key_id = "${aws_kms_key.k.key_id}"
}

resource "aws_security_group" "application_security" {
  name = "application_security"
  vpc_id = "${aws_vpc.default.id}"

  # HTTP access from the VPC
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "${aws_vpc.default.cidr_block}"
    ]
  }

  # Elastic Beanstalk clock sync
  egress {
    from_port = 123
    to_port = 123
    protocol = "udp"
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

resource "aws_security_group" "rds_security" {
  name = "rds_security"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = ["${aws_security_group.application_security.id}"]
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

resource "aws_db_subnet_group" "rds" {
  name = "rds"
  subnet_ids = [
    "${aws_subnet.private.id}",
    "${aws_subnet.private_2.id}"
  ]

  tags {
    Name = "DB Subnet"
  }
}

resource "aws_db_instance" "db" {
  allocated_storage = 10
  availability_zone = "us-east-1a"
  db_subnet_group_name = "${aws_db_subnet_group.rds.name}"
  engine = "postgres"
  instance_class = "db.m3.medium"
  kms_key_id = "${aws_kms_key.k.arn}"
  name = "rails_aws_starter"
  username = "juliebanana"
  password = "${var.rds_password}"
  storage_encrypted = true
  storage_type = "gp2"
  vpc_security_group_ids = ["${aws_security_group.rds_security.id}"]
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
    namespace = "aws:autoscaling:launchconfiguration"
    name = "SecurityGroups"
    value = "${aws_security_group.application_security.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "VPCId"
    value = "${aws_vpc.default.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "Subnets"
    value = "${aws_subnet.private.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "ELBSubnets"
    value = "${aws_subnet.public.id}"
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
