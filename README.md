# IAC-pipeline
**Tools**
Checkov is utilised for quality checks.
Terragrunt is required in your project set up, it is used for deployment and drift detection.

**Permissions**
The following permissions will need to be configured on the caller repo.

```
permissions:
  pull-requests: write
  actions: read
  security-events: write
  contents: read
```

**Supports**
Terraform
Terragrunt
Amazon Web Services
Google Cloud
Azure
Checkov

**Setup**
This project can be called from another repositorys workflow.

This workflow will run in two parts, a CI and a CD.
The CI process is triggered when a pull request opens.
The CD process will run when the pull request closes, if no merge has occured no deployment will occur.

An example of how to set up this project call for GCP can be seen below.

```
name: run-ci
on:
    workflow_call:

    pull_request:
        #opened is set so a CI can run when a PR is created
        branches:
            - main
            - test
            - develop
        types: [opened, synchronize, reopened, closed]
permissions:
  pull-requests: write
  actions: read
  security-events: write
  contents: read

jobs:
    run-ci:
        uses: iac-pipeline/iac-pipeline/.github/workflows/terraform_ci.yml@master
        with:
            iac_technology: "Terraform"
            cloud_provider: "GCP"
            environments: |
                develop: dev
                test: test
                main: prod
        secrets:
            cloud_token: '${{ secrets.CLOUD_PROVIDER_SECRET }}'
```


**Keys**

**Required**

```environments: |``` is required to configure the environments that code needs to be promoted through.
environments can be configured to define what branch is relavent to what environment.
This is required in order to assosciate a branch to a terragrunt developement pathway for example
```/terragrunt/live/dev/cloud_storage/```
As a example the following states that the ```develop``` branch points to the ```dev``` environment there by looking for a pathway that includes ```dev```.
```
environments: |
                develop: dev
                test: test
                main: prod
```

```iac_technology``` This key is for the IaC language being utilised. Currently only Terraform is supported.

```cloud_provider``` This is for the cloud proider being utilised. Currently the following are supported.
    - GCP
    - AWS
    - Azure

**Optional**

```iac_technology_version``` This key allows for the version of choice for the users IaC language to be utilised.  Defaults to "1.7.5".

```repo_terragrunt_version``` This key allows for a version of terragrunt to be utilised. Defaults to "0.99.1"

```checkov_custom_policy_file_path``` This key allows for custom checkov policys to be used in the same directory. Set this value to the filepath from route for the policy file. Only Yaml policys are supported by the pipeline.
                                      

***Secrets***

***AWS Auth***
    
    ```aws_region``` - This key should be the default AWS region.
    
    ```aws_secret_access_key``` - AWS IAM secret access key.
    
    ```aws_access_key_id``` - ID of the relavent access key

***GCP***
    ```cloud_token``` - Access token for the cloud provider in question.

***Azure***
    ```cloud_token``` - Please congifure as a service principle secret.
                      - https://github.com/marketplace/actions/azure-login

**Design**
<img width="648" height="1098" alt="diss pipeline drawio" src="https://github.com/user-attachments/assets/327d89ad-285e-49b5-b114-1a5b97ac3ee5" />

