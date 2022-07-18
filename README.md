# Environment Infrastructure `core` module

This directory contains a [Terraform module](https://learn.hashicorp.com/tutorials/terraform/module)
containing [Terraform configuration](https://www.terraform.io/language/syntax/configuration)
for a Platykus platform environment running on an [AWS EKS cluster](https://aws.amazon.com/eks/).

## Organization

This module is organized as follows.

- the [`cluster`](cluster) directory is a submodule containing configuration
  for all platform cluster AWS resources
- the [`Makefile`](Makefile) provides project automation

> NOTE: Do not edit the tables below directly. They are generated by with the
> `make docs` command.

<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.2 |
| aws | 4.22.0 |
| helm | 2.6.0 |
| kubernetes | 2.12.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_region | AWS region | `string` | n/a | yes |
| aws_subnet_ids | AWS VPC subnets | `list(string)` | n/a | yes |
| aws_vpc_id | AWS VPC to use | `string` | n/a | yes |
| cluster_version | EKS cluster version | `string` | `"1.21"` | no |
| eks_managed_node_group_defaults | Map of EKS managed node group default configurations | `any` | <pre>{<br>  "disk_size": 50,<br>  "iam_role_attach_cni_policy": true,<br>  "instance_types": [<br>    "m5.xlarge"<br>  ]<br>}</pre> | no |
| eks_managed_node_groups | Map of EKS managed node group definitions to create | `any` | <pre>{<br>  "default_node_group": {<br>    "create_launch_template": false,<br>    "disk_size": 50,<br>    "launch_template_name": ""<br>  }<br>}</pre> | no |
| environment | Environment name | `string` | n/a | yes |
| system | System name | `string` | n/a | yes |
| tags | Environment tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| eks_cluster_arn | The Amazon Resource Name (ARN) of the EKS cluster. |
| eks_cluster_id | EKS cluster name |
| eks_cluster_oidc_issuer_url | EKS cluster OIDC Issuer URL |
| eks_cluster_oidc_provider_arn | EKS cluster OIDC Provider ARN |
| vpc-cni_iam_role_arn | vpc-cni EKS addon IRSA role ARN |
| vpc-cni_iam_role_name | vpc-cni EKS addon IRSA role name |
| vpc-cni_iam_role_path | vpc-cni EKS addon IRSA role path |
| vpc-cni_iam_role_unique_id | vpc-cni EKS addon IRSA role unique id |

<!-- END_TF_DOCS -->
