terraform {
  backend "s3" {
    bucket = "rails-aws-starter"
    region = "us-east-1"
    key = "state.tf"
  }
}

# Specify the provider and access details
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
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
  availability_zone = "${var.aws_az1}"
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

  # SSH
  ingress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 22
    to_port = 22
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
  cidr_block = "10.0.2.0/24"
  availability_zone = "${var.aws_az1}"
  tags {
    Name = "private"
  }
}

# Create a second private subnet for RDS fallback
resource "aws_subnet" "private_2" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "10.0.3.0/24"
  availability_zone = "${var.aws_az2}"
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

  # SSH
  ingress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 22
    to_port = 22
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

  tags {
    Name = "private"
  }
}

resource "aws_kms_key" "k" {
  description = "database encryption key"
}

resource "aws_kms_alias" "k" {
  name = "alias/rails-aws-starter"
  target_key_id = "${aws_kms_key.k.key_id}"
}

resource "aws_key_pair" "auth" {
  key_name = "${var.key_name}"
  public_key = "${var.public_key}"
}

resource "aws_security_group" "bastion_security" {
  name = "bastion_security"
  vpc_id = "${aws_vpc.default.id}"

  # SSH access from CfA
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "69.12.169.82/32"
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

resource "aws_security_group" "application_security" {
  name = "application_security"
  vpc_id = "${aws_vpc.default.id}"

  # SSH access from the VPC
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "${aws_vpc.default.cidr_block}"
    ]
  }

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

resource "aws_instance" "bastion" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "ec2_user"

    # The connection will use the local SSH agent for authentication.
  }

  tags {
    Name = "bastion"
  }

  instance_type = "t2.micro"
  # Amazon Linux AMI 2018.03.a x86_64 ECS HVM GP2 in us-east-1
  ami = "ami-fbc1c684"
  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = [
    "${aws_security_group.bastion_security.id}"
  ]
  subnet_id = "${aws_subnet.public.id}"
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.bastion_instance_profile.name}"
}

resource "aws_iam_role" "bastion_role" {
  name = "bastion_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "bastion_logs_to_cloudwatch" {
  role = "${aws_iam_role.bastion_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_iam_instance_profile" "bastion_instance_profile" {
  name = "bastion_instance_profile"
  role = "${aws_iam_role.bastion_role.name}"
}

resource "aws_iam_role_policy_attachment" "application_logs_to_cloudwatch" {
  role = "${aws_iam_role.instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_iam_instance_profile" "application_instance_profile" {
  name = "application_instance_profile"
  role = "${aws_iam_role.instance_role.name}"
}

resource "aws_db_subnet_group" "default" {
  name = "main"
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
  availability_zone = "${var.aws_az1}"
  db_subnet_group_name = "${aws_db_subnet_group.default.name}"
  engine = "postgres"
  instance_class = "db.m3.medium"
  kms_key_id = "${aws_kms_key.k.arn}"
  name = "rails_aws_starter"
  username = "${var.rds_username}"
  password = "${var.rds_password}"
  storage_encrypted = true
  storage_type = "gp2"
  vpc_security_group_ids = ["${aws_security_group.rds_security.id}"]
  skip_final_snapshot = "true" # To remove
}

# Beanstalk application
resource "aws_elastic_beanstalk_application" "beanstalk_app" {
  name = "${var.app_name}"
}

resource "aws_iam_role" "instance_role" {
  name = "instance_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role" "beanstalk_role" {
  name = "beanstalk_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticbeanstalk.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "elasticbeanstalk"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eb_enhanced_health" {
  role = "${aws_iam_role.beanstalk_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "eb_service" {
  role = "${aws_iam_role.beanstalk_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

resource "aws_iam_role_policy_attachment" "web_tier" {
  role = "${aws_iam_role.instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_elastic_beanstalk_environment" "beanstalk_env" {
  name = "${var.app_name}-${var.app_env}"
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
    name = "IamInstanceProfile"
    value = "${aws_iam_instance_profile.application_instance_profile.name}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "SecurityGroups"
    value = "${aws_security_group.application_security.id}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name = "ServiceRole"
    value = "${aws_iam_role.beanstalk_role.name}"
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
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name = "SystemType"
    value = "enhanced"
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
//
//  setting {
//    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
//    name = "StreamLogs"
//    value = "true"
//  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name = "DeleteOnTerminate"
    value = "false"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name = "RetentionInDays"
    value = "3653"
  }
}

resource "aws_iam_role" "cloudwatch_logs_role" {
  name = "cloudwatch_logs_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "cloudwatch_s3_attach" {
  role = "${aws_iam_role.cloudwatch_logs_role.name}"
  policy_arn = "${aws_iam_policy.cloudwatch_s3_policy.arn}"
}

resource "aws_iam_policy" "cloudwatch_s3_policy" {
  name = "cloudwatch_s3"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailCreateAndUpdateS3LogStream",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "${aws_cloudwatch_log_group.log_access_logs.arn}:*",
        "${aws_cloudwatch_log_group.management_logs.arn}:*"
      ]
    }
  ]
}
POLICY
}

resource "aws_cloudtrail" "log_access_logs" {
  name = "log-access-logs-${var.app_name}-${var.app_env}"
  s3_bucket_name = "${aws_s3_bucket.cloudtrail_log_access_logs.id}"
  include_global_service_events = false
  enable_log_file_validation = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.log_access_logs.arn}"
  cloud_watch_logs_role_arn = "${aws_iam_role.cloudwatch_logs_role.arn}"

  event_selector {
    read_write_type = "All"
    include_management_events = false

    data_resource {
      type = "AWS::S3::Object"
      values = [
        "${aws_s3_bucket.cloudtrail_management_logs.arn}/"
      ]
    }
  }
}

resource "aws_cloudtrail" "management_logs" {
  name = "management-logs-${var.app_name}-${var.app_env}"
  s3_bucket_name = "${aws_s3_bucket.cloudtrail_management_logs.id}"
  include_global_service_events = true
  enable_log_file_validation = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.management_logs.arn}"
  cloud_watch_logs_role_arn = "${aws_iam_role.cloudwatch_logs_role.arn}"
}

resource "aws_s3_bucket" "cloudtrail_log_access_logs" {
  bucket = "cloudtrail-log-access-logs-${var.app_name}-${var.app_env}"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::cloudtrail-log-access-logs-${var.app_name}-${var.app_env}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::cloudtrail-log-access-logs-${var.app_name}-${var.app_env}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Sid": "DenyUnSecureCommunications",
            "Effect": "Deny",
            "Principal": {
              "AWS": "*"
            },
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::cloudtrail-log-access-logs-${var.app_name}-${var.app_env}/*",
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_s3_bucket" "cloudtrail_management_logs" {
  bucket = "cloudtrail-management-logs-${var.app_name}-${var.app_env}"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::cloudtrail-management-logs-${var.app_name}-${var.app_env}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::cloudtrail-management-logs-${var.app_name}-${var.app_env}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Sid": "DenyUnSecureCommunications",
            "Effect": "Deny",
            "Principal": {
                "AWS": "*"
            },
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::cloudtrail-management-logs-${var.app_name}-${var.app_env}/*",
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_cloudwatch_log_group" "log_access_logs" {
  name = "log_access_logs"
}

resource "aws_cloudwatch_log_group" "management_logs" {
  name = "management_logs"
}
