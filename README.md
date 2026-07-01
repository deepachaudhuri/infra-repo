# Infra repo for test environment

This Terraform configuration creates a test VPC using the shared module from the aws-modules folder.

## Remote state backend

This repo uses an S3 backend for Terraform state.

In GitHub Actions, the workflow initializes Terraform with the S3 backend using the following values:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `TF_STATE_BUCKET`

The state file key is set per branch as:

`infra-repo/${{ github.event_name == 'pull_request' && github.base_ref || github.ref_name }}.tfstate`

## Run

```bash
cd infra-repo
terraform init
terraform plan
terraform apply
```
