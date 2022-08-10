### Deployment Steps
Deploy Terraform first, then deploy Packer

#### Terraform Deployment
* If using Terraform Cloud deployment strategy, just push to your relevant deployment branch

#### Packer Deployment
* packer build -var-file="packer-vars.pkrvars.hcl" .