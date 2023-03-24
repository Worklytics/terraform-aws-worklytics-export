# Basic Worklytics Export to S3 Example

We don't recommend *direct* use of this example, but rather use it as a reference for how to add
the Worklytics Export module to your own Terraform configuration or as a working example when
developing the module itself.


## Usage for Development

Within `examples/basic/` (eg, here), create a `terraform.tfvars` file with the following content,
customizing  AWS account id and role name as needed.

```hcl
worklytics_tenant_id = null # "123456712345671234567"
aws_account_id       = "626567183302" # our CI account!! use your own!
aws_role_name        = "Admin"
```

Then test the example:

```shell
terraform init
terraform apply
```
