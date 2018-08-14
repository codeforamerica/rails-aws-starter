# Rails AWS Starter Application

A starter Rails app for Code for America products that includes out-of-the-box configuration for the following:

* Postgres as database
* Rspec for tests
* [GCF styleguide](https://github.com/codeforamerica/cfa-styleguide-gem)
* Terraform script for creating deployment environment
* CircleCI config with deployment pipeline (staging, demo, production environments)

Currently a work-in-progress.

## Initial Setup

### First deploy

1. Create a new key pair locally (`ssh-keygen -t rsa -b 4096 -C "your_email@example.com"`). Safely store the keyfiles, and run `chmod 400 my-key-pair` on the private key so that only you can read it. Add the generated public key (e.g. `my-key-pair.pub`) to the varfile as `public_key`.

1. [Initialize the terraform backend and apply the initial configuration](./deploy/README.md) (default name is `rails-aws-starter-sandbox`).

1. Upon initial creation, enable access to the Bastion instance for each user that requires SSH access:
    
    1. Generate a new key pair (either locally or in AWS console) for each additional user that requires SSH access. Safely store the keyfiles, and run `chmod 400 my-key-pair` on the private key so that only you can read it. Add name and public key information for each user, including the initially generated key, to `adduser.sh`. Commit and push the script before running an `eb deploy` below, as the public keys will be added to the application instances at that time.

    1. Use these private key generated in step one as credentials and run the bastion setup script with: `./bastion_setup.sh <ip address>`, which creates individual user accounts and sets up logging to CloudWatch from the bastion.

1. Install the Elastic Beanstalk CLI (`brew update && brew install awsebcli`) and [configure with your AWS credentials](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-configuration.html#eb-cli3-credentials).

1. Initialize Elastic Beanstalk `eb init --region <preferred-region>` and choose the environment created above (`rails-aws-starter-sandbox`). For region, this sample app uses `us-east-1`.

1. Deploy the application by running `eb deploy rails-aws-starter-sandbox`.


### First deploy (all environments, with promotion pipeline)

Our CircleCI config details three environments: staging, promotion, and production. To create these environments for use with CircleCI, you can use the script and steps detailed above—you'll just have to do the following for each environment:

1. Create a separate AWS account (e.g. using `rails-aws-starter+staging@codeforamerica.org`, `rails-aws-starter+demo@codeforamerica.org`, `rails-aws-starter+production@codeforamerica.org`)

1. Complete the [first deploy] steps for each environment

Once the deployment environments are all in place, update the CircleCI config as detailed below, and trigger a build.


### CircleCI

We use CircleCI to run tests and deploy to our various environments, by running the following tasks:

1. Install dependencies
1. In parallel:
    1. Run checks (i.e. bundle-audit)
    1. Run tests
1. Deploy to staging environment
1. Approving for deploy to production
1. In parallel:
    1. Tag the release and push to Github
    1. Deploy to production environment
    1. Deploy to demo environment

In order to set up the above functionality, you'll need to configure the following:

1. Replace each `APP_ENV_NAME` value (i.e. for staging, demo, and production) with the appropriate AWS environment name
    e.g.
    ```
      environment:
        APP_ENV_NAME: REPLACE_ME
    ```
    becomes
    ```
      environment:
        APP_ENV_NAME: rails-starter-staging
    ```
1. Add the SSH key fingerprint for the read/write deploy key that was added to AWS at the following location:
    ```
      - add_ssh_keys:
          fingerprints:
            - "REPLACE ME: READ/WRITE DEPLOY KEY FINGERPRINT"
    ```

## To SSH to the EC2 instance via the bastion host

Add your credentials to your local SSH agent by running `ssh-add <key>`. SSH to the instance by proxying through the Bastion by running: `ssh -o ProxyCommand='ssh -W %h:%p <username>@<bastion public ip>' <username>@<instance private ip>`

## Contributing
Bug reports and pull requests are welcome on GitHub at [https://github.com/codeforamerica/rails-aws-starter](https://github.com/codeforamerica/rails-aws-starter). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the Contributor Covenant code of conduct.

## License

The application is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Rails AWS Starter project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/codeforamerica/rails-aws-starter/blob/master/CODE_OF_CONDUCT.md).
