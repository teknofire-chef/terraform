# Terraform for teknofire stuff

Base set of terraform plans to setup testing environments.  Terraform state is stored locally on the filesystem.  It is possible to configure this to save to a S3 bucket but that will be something for a later time.

There is a common VPC state read from the other terraform plans in order to have a shared set of subnet ips and security groups.  It's also possible to setup additional environments that can pull the state from another set of plans.

This will includes setting up a common set of tags that get applied to all resources that are created.

## Requirements

* Terraform v0.11.5
  + provider.aws v0.1.4
  + provider.null v0.1.0

## Setup

Create a `terraform.tfvars` file to save secrets and your environment configurations.

  This file will not get saved to git and can be used to remember secrets and other common variables used by the terraform plan. To see examples of how to add additional variables see: https://www.terraform.io/docs/configuration/variables.html#variable-files

  You can use the example file in `template/terraform.tfvars` and either add it to each plan directory as `terraform.tfvars` or create a common file that you load using the `--var-file` cli option.

  For example my `~/.terraform/terraform.tfvars`

```
namespace = "teknofire"
aws_profile = "default"
aws_key_name = "teknofire"
allowed_cidrs = ["70.112.191.11/32"]
default_tags = {
  X-Contact = "Will"
  X-Created-By = "will@teknofire.net"
}
admin_email = "will@teknofire.net"
chef_password = "REDACTED"
instance_type = "m3.medium"
vpc_cidr = "10.80.0.0/16"
vpc_public_subnets = ["10.80.30.0/24", "10.80.40.0/24"]
```

## Using plans

Running `terraform plan` using a shared variable file:

```bash
terraform plan --var-file=~/.terraform/terraform.tfvars
```

Some aliases that you can add to your `~/.bashrc` or `~/.zshrc` to make this easier

```
alias ts='terraform show'
alias tpv='terraform plan --var-file ~/.terraform/terraform.tfvars'
alias tav='terraform apply --var-file ~/.terraform/terraform.tfvars'
alias tdv='terraform destroy --var-file ~/.terraform/terraform.tfvars'
```

This first thing you will need to do is to get your VPC up and running. To run the plans for the VPC you must be in the `vpc` directory.  

**Example commands to setup the VPC:**

```bash
cd vpc

# this command is only required the very first time you use a new setup of plan files
terraform init

# see what might change
terraform plan --var-file ~/.terraform/terraform.tfvars

# if everything looks good apply it!
terraform apply --var-file ~/.terraform/terrform.tfvars

# to see the variables at a later time
terraform show --var-file ~/.terraform/terraform.tfvars
```

After the VPC is setup you will be able to go into the other plan directories and create and destroy additional infrastructure.

**Example commands to setup chef-server**
```bash
cd ../chef-server

# this command is only required the very first time you use a new setup of plan files
terraform init

# see what might change
terraform plan --var-file ~/.terraform/terraform.tfvars

# if everything looks good apply it!
terraform apply --var-file ~/.terraform/terrform.tfvars

# to see the variables at a later time
terraform show --var-file ~/.terraform/terraform.tfvars

# destroy all the things
terraform destroy --var-file ~/.terraform/terraform.tfvars

```

## Plan descriptions

### Template

This is just a basic set of files that can be used when creating a new set of terraform plans.

```bash
cp -rv template awesome_sauce_resources
```

### vpc

This is the base VPC that will be created and used by other plans for IP subnets and default security groups.

The following security groups are created

* `default` - allows connections to ssh in from the `allowed_cidrs`
* `windows_default` - allows connections to various winrm ports from the `allowed_cidrs` and members of the `default` security group
* `http` - allows connections to 80/443 ports from the `allowed_cidrs` and members of the `default` security group

### chef-server

This will stand up a chef-server with a `chefadmin` user.  The keys that get generated for those accounts are saved in `/drop/{USERNAME}.pem` and by default will attempt to save them to a `../../.chef/` on your local system.

## Magic stuff

### terraform state sharing

The magic that is used to pull in state information from another terraform environment is the following code that you can find in the `template/main.tf` file

```terraform
data "terraform_remote_state" "vpc" {
  backend = "local"

  config {
    path = "${path.module}/#{var.vpc_state_path}"
  }
}
```

At this point you can then reference any output variables that have been defined in the plan using `${data.terraform_remote_state.vpc.OUTPUT_VAR_NAME}`


Example:
```terraform
resource "aws_instance" "chef-server" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.medium"
  key_name      = "wfisher"
  subnet_id     = "${data.terraform_remote_state.vpc.public_subnets[0]}"
  vpc_security_group_ids = ["${data.terraform_remote_state.vpc.default_sg_id}","${data.terraform_remote_state.vpc.http_sg_id}"]
  lifecycle {
   ignore_changes = "ami"
  }
  tags = "${merge(var.default_tags, map("Name", format("%s", "${var.namespace}-chef-server")))}"
}
```

### Finding AMI ids automagically

The following plan info will search for the latest ubuntu 16.04 ami for the current region.  Which can then be referenced in a plan using: `"${data.aws_ami.ubuntu.id}"`

```terraform
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
```
