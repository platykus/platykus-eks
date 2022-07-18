variable "tags" {
  description = "AWS resource tags"
  type        = map(string)
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_subnet_ids" {
  description = "AWS VPC subnets"
  type        = list(string)
}

variable "aws_vpc_id" {
  description = "AWS VPC"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
}

variable "eks_managed_node_group_defaults" {
  description = "Map of EKS managed node group default configurations"
  type        = any
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions to create"
  type        = any
}
