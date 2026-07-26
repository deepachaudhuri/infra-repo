# Terraform Destroy Workflow - Step-by-Step Guide

This guide explains how to use the GitHub Actions Terraform Destroy workflow to safely destroy your AWS infrastructure resources.

## Prerequisites

Before running the destroy workflow, ensure:

1. **GitHub Secrets are configured** in your repository settings:
   - `AWS_ACCESS_KEY_ID` - Your AWS access key
   - `AWS_SECRET_ACCESS_KEY` - Your AWS secret key

2. **GitHub Variables are configured** in your repository settings:
   - `TF_STATE_BUCKET` - Your S3 bucket name storing Terraform state files

3. **Terraform state file exists** in your S3 bucket for the environment you want to destroy

4. **You have appropriate permissions** to destroy resources in the selected environment

## Step-by-Step Instructions to Run Destroy

### Step 1: Navigate to GitHub Actions

1. Go to your GitHub repository
2. Click on the **Actions** tab in the top navigation bar

### Step 2: Select Destroy Workflow

1. On the left sidebar under "Workflows", find and click on **Terraform Destroy**
2. You'll see the workflow history (if any previous runs exist)

### Step 3: Trigger the Workflow

1. Click the **Run workflow** button (green button on the right)
2. A dropdown menu will appear with input options

### Step 4: Select Environment to Destroy

1. In the **Environment to destroy** dropdown, select one of:
   - **dev** - Development environment
   - **stage** - Staging environment
   - **prod** - Production environment

2. Click the green **Run workflow** button to start the destroy process

### Step 5: Monitor Workflow Execution

1. The workflow will execute automatically with these steps:

   - **Checkout repository** - Downloads your code
   - **Configure AWS credentials** - Authenticates with AWS using secrets
   - **Setup Terraform** - Installs latest Terraform version
   - **Terraform init** - Initializes Terraform and connects to your state backend
   - **Terraform validate** - Validates your Terraform configuration
   - **Terraform plan (destroy)** - Creates a destroy plan showing what will be deleted
   - **Terraform destroy** - Executes the destroy plan and removes resources

2. Watch the workflow progress in the **Actions** tab
3. Click on the running job to see detailed logs

### Step 6: Review Logs (Optional)

1. During execution, you can click on any step to expand and view its logs
2. Look for the **Terraform plan (destroy)** step to see what resources will be destroyed
3. Check the **Terraform destroy** step to verify successful destruction

## Important Warnings ⚠️

- **IRREVERSIBLE**: Destroy operations cannot be undone. Resources will be permanently deleted.
- **PROD CAREFUL**: When destroying prod environment, ensure you have backups and approvals.
- **STATE FILE**: Make sure your S3 backend is properly configured before destroying.
- **DEPENDENCIES**: Some resources may fail to destroy if they have dependencies or are locked.

## Workflow Comparison

| Step | Deploy Workflow | Destroy Workflow |
|------|-----------------|------------------|
| Trigger | Auto (push/PR) | Manual (workflow_dispatch) |
| Action | `terraform plan` → `terraform apply` | `terraform plan -destroy` → `terraform apply` |
| Effect | Creates/Updates resources | Deletes all resources |
| Rollback | Previous state available | Resources permanently deleted |

## Troubleshooting

### Workflow Not Appearing in Actions Tab
- **Solution**: Ensure the `terraform-destroy.yml` file is in `.github/workflows/` directory on your main/default branch

### AWS Credentials Error
- **Solution**: Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` secrets are correctly set in GitHub

### Terraform Init Fails
- **Solution**: Check that `TF_STATE_BUCKET` variable is set correctly and bucket exists in S3

### Resources Won't Destroy
- **Solution**: Some resources may have deletion protection. Check AWS console and manually remove if needed

### Environment Not Showing in Dropdown
- **Solution**: Ensure GitHub Environments are created (Settings → Environments) for dev, stage, and prod

## Security Best Practices

1. **Restrict Access**: Only give destroy permissions to trusted team members
2. **Environment Protection**: Add branch protection rules and required approvals for prod
3. **Audit Logs**: Review GitHub Action logs after each destroy operation
4. **Backup**: Always backup critical data before destroying resources
5. **Use Variables**: Never hardcode sensitive information; use GitHub Secrets and Variables

## Additional Commands

### Manual Destroy (If Needed)

If you need to destroy resources manually from your local machine:

```bash
# Initialize terraform
terraform init \
  -backend-config="bucket=YOUR_BUCKET" \
  -backend-config="key=infra-repo/dev.tfstate" \
  -backend-config="region=us-east-1"

# Plan destroy
terraform plan -destroy -out=tfplan

# Apply destroy
terraform apply tfplan
```

## Contact & Support

For issues or questions about the destroy workflow:
- Check GitHub Actions logs for detailed error messages
- Review Terraform documentation: https://www.terraform.io/docs/commands/destroy.html
- Contact your DevOps/Infrastructure team
