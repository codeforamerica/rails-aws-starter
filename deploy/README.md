### Setting up terraform backend on S3

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