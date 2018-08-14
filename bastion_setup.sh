#!/usr/bin/env bash

IP=$1

scp adduser.sh ec2-user@${IP}:
ssh ec2-user@${IP} -C "chmod a+x ./adduser.sh && sudo ./adduser.sh"

ssh ec2-user@${IP} -C "sudo yum update -y && sudo yum install -y awslogs"
scp bastion_awslogs.conf ec2-user@${IP}:awslogs.conf
ssh ec2-user@${IP} -C "sudo mv awslogs.conf /etc/awslogs/awslogs.conf && sudo service awslogs restart"
