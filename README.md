# Rails AWS Starter Application

A starter Rails app for Code for America products that includes out-of-the-box configuration for the following:

* Postgres as database
* Rspec for tests
* [GCF styleguide](https://github.com/codeforamerica/cfa-styleguide-gem)
* CircleCI config with deployment pipeline (staging, demo, production environments)

Currently a work-in-progress.

## Initial Setup

### AWS

TODO

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


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Rails AWS Starter project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/codeforamerica/rails-aws-starter/blob/master/CODE_OF_CONDUCT.md).
