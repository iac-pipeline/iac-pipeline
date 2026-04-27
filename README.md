# IAC-pipeline
**Tools**
Checkov is utilised for quality checks.
Terragrunt is required in your project set up, it is used for deployment and drift detection.

**Supports**
Terraform
Terragrunt
Amazon Web Services
Google Cloud
Azure

**Setup**
This project can be called from another repositorys workflow.

This workflow will run in two parts, a CI and a CD.
The CI process is triggered when a pull request opens.
The CD process will run when the pull request closes, if no merge has occured no deployment will occur.

An example of how to set up this project call can be seen below

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


**Design**
<img width="651" height="1102" alt="diss pipeline(6)" src="https://github.com/user-attachments/assets/d8533317-d35c-4fbb-b4fd-ce671617d6f2" />
