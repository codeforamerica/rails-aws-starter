# Using terraform to create hosted environments

This script should be used to create a new hosted environment (e.g. staging, demo, production) for an application.

Terraform is used to automate the initial deployment. To use these instructions, you'll first need to install terraform (available via homebrew as `brew install terraform`).

## To initialize an S3 backend for Terraform state

1. Create a bucket

1. Create a custom policy to give the user read/write/list access to the S3 bucket.
    ```
    {
         "Version": "2012-10-17",
         "Statement": [
             {
                 "Sid": "AllowViewBucketInfo",
                 "Effect": "Allow",
                 "Action": [
                     "s3:ListBucket",
                     "s3:GetBucketLocation"
                 ],
                 "Resource": "arn:aws:s3:::<bucket-name>"
             },
             {
                 "Sid": "AllowReadWriteToBucket",
                 "Effect": "Allow",
                 "Action": [
                    "s3:GetObject",
                    "s3:PutObject"
                 ]
                 "Resource": "arn:aws:s3:::<bucket-name>/*"
             }
         ]
     }
    ```
    
1. Create an IAM user and attach the custom policy to it.

1. In `deploy/backend-configs/`, create a file called `sandbox` which contains the Amazon access key id and secret access key for that IAM user. An example template is provided at `backend-config.example`.

    Note: These backends will be environment specific, so name them accordingly.

1. Initialize the local directory by running `terraform init -backend-config=./backend-configs/sandbox`

## Applying changes

1. Run `terraform apply -var-file ./varfiles/sandbox`.
