data "aws_caller_identity" "current" {}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.26.3"

  tags = var.tags

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni    = {
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.vpc-cni.iam_role_arn
    }
  }

  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources        = ["secrets"]
    }
  ]

  cluster_tags = var.tags

  # Network config
  vpc_id     = var.aws_vpc_id
  subnet_ids = var.aws_subnet_ids

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description = "Node all egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = var.eks_managed_node_group_defaults
  eks_managed_node_groups         = var.eks_managed_node_groups
}

# References to resources that do not exist yet when creating a cluster will cause a plan failure due to https://github.com/hashicorp/terraform/issues/4149
# There are two options users can take
# 1. Create the dependent resources before the cluster => `terraform apply -target <your policy or your security group> and then `terraform apply`
#   Note: this is the route users will have to take for adding additional security groups to nodes since there isn't a separate "security group attachment" resource
# 2. For additional IAM policies, users can attach the policies outside of the cluster definition as demonstrated below
resource "aws_iam_role_policy_attachment" "additional" {
  for_each = module.eks.eks_managed_node_groups

  policy_arn = aws_iam_policy.node_additional.arn
  role       = each.value.iam_role_name
}

resource "aws_security_group" "additional" {
  name_prefix = "${var.cluster_name}-additional"
  vpc_id      = var.aws_vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }

  tags = var.tags
}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.tags
}

resource "aws_kms_key" "ebs" {
  description             = "Customer managed key to encrypt EKS managed node group volumes"
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.ebs.json
}

# This policy is required for the KMS key used for EKS root volumes, so the cluster is allowed to enc/dec/attach encrypted EBS volumes
data "aws_iam_policy_document" "ebs" {
  # Copy of default KMS policy that lets you manage it
  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # Required for EKS
  statement {
    sid     = "Allow service-linked role use of the CMK"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
        # required for the ASG to manage encrypted volumes for nodes
        module.eks.cluster_iam_role_arn, # required for the cluster / persistentvolume-controller to create encrypted PVCs
      ]
    }
  }

  statement {
    sid       = "Allow attachment of persistent resources"
    actions   = ["kms:CreateGrant"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
        # required for the ASG to manage encrypted volumes for nodes
        module.eks.cluster_iam_role_arn, # required for the cluster / persistentvolume-controller to create encrypted PVCs
      ]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

# This is based on the LT that EKS would create if no custom one is specified (aws ec2 describe-launch-template-versions --launch-template-id xxx)
# there are several more options one could set but you probably dont need to modify them
# you can take the default and add your custom AMI and/or custom tags
#
# Trivia: AWS transparently creates a copy of your LaunchTemplate and actually uses that copy then for the node group. If you DONT use a custom AMI,
# then the default user-data for bootstrapping a cluster is merged in the copy.

resource "aws_launch_template" "external" {
  name_prefix            = "${var.cluster_name}-external-eks-"
  description            = "EKS managed node group external launch template"
  update_default_version = true

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 100
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = true
  }

  # Disabling due to https://github.com/hashicorp/terraform-provider-aws/issues/23766
  # network_interfaces {
  #   associate_public_ip_address = false
  #   delete_on_termination       = true
  # }

  # if you want to use a custom AMI
  # image_id      = var.ami_id

  # If you use a custom AMI, you need to supply via user-data, the bootstrap script as EKS DOESNT merge its managed user-data then
  # you can add more than the minimum code you see in the template, e.g. install SSM agent, see https://github.com/aws/containers-roadmap/issues/593#issuecomment-577181345
  # (optionally you can use https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/cloudinit_config to render the script, example: https://github.com/terraform-aws-modules/terraform-aws-eks/pull/997#issuecomment-705286151)
  # user_data = base64encode(data.template_file.launch_template_userdata.rendered)

  tag_specifications {
    resource_type = "instance"
    tags          = var.tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = var.tags
  }

  tag_specifications {
    resource_type = "network-interface"
    tags          = var.tags
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_policy" "node_additional" {
  name        = "${var.cluster_name}-additional"
  description = "Example usage of node additional policy"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = var.tags
}

data "aws_ami" "eks_default" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.cluster_version}-v*"]
  }
}

output "eks_cluster_arn" {
  value       = module.eks.cluster_arn
  description = "The Amazon Resource Name (ARN) of the EKS cluster."
}

output "eks_cluster_certificate_authority_data" {
  value       = module.eks.cluster_certificate_authority_data
  description = "EKS cluster Kubernetes API cert data"
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS cluster Kubernetes API endpoint."
}

output "eks_cluster_id" {
  value       = module.eks.cluster_id
  description = "The name/id of the EKS cluster."
}

output "eks_cluster_oidc_issuer_url" {
  value       = module.eks.cluster_oidc_issuer_url
  description = "The URL of the EKS cluster OIDC Issuer"
}

output "eks_cluster_oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "The ARN of the OIDC Provider"
}
