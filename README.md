### Deployment Steps
Deploy Terraform first, then deploy Packer

#### Terraform Deployment
* If using Terraform Cloud deployment strategy, just push to your relevant deployment branch

#### Packer Deployment
* packer build -var-file="packer-vars.pkrvars.hcl" .

### TODO
* Set up automation for Packer to get the ECR repo URL via Parameter Store instead of a hardcoded variable
  * Packer can use Parameter Store as a data source but not ECR