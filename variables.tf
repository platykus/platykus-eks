################################################################################
# Platform identity
################################################################################

variable "system" {
  description = "System name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Environment tags"
  type        = map(string)
  default     = {}
}

################################################################################
# terraform-aws-eks module config passed through to module
# See https://github.com/terraform-aws-modules/terraform-aws-eks for details
################################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_subnet_ids" {
  description = "AWS VPC subnets"
  type        = list(string)
}

variable "aws_vpc_id" {
  description = "AWS VPC to use"
  type        = string
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.21"
}

variable "eks_managed_node_group_defaults" {
  description = "Map of EKS managed node group default configurations"
  type        = any
  default     = {
    disk_size      = 50
    instance_types = ["m5.xlarge"]

    # We are using the IRSA created below for permissions
    # However, we have to deploy with the policy attached FIRST (when creating a fresh cluster)
    # and then turn this off after the cluster/node group is created. Without this initial policy,
    # the VPC CNI fails to assign IPs and nodes cannot join the cluster
    # See https://github.com/aws/containers-roadmap/issues/1666 for more context
    iam_role_attach_cni_policy = true
  }
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions to create"
  type        = any
  default     = {
    # Default node group - as provided by AWS EKS
    default_node_group = {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      create_launch_template = false
      launch_template_name   = ""

      disk_size = 50
    }
  }
}
