module "cluster" {
  source = "./cluster"

  aws_region                      = var.aws_region
  aws_subnet_ids                  = var.aws_subnet_ids
  aws_vpc_id                      = var.aws_vpc_id
  cluster_name                    = local.identity
  cluster_version                 = var.cluster_version
  eks_managed_node_group_defaults = var.eks_managed_node_group_defaults
  eks_managed_node_groups         = var.eks_managed_node_groups
  tags                            = local.tags
}

output "eks_cluster_arn" {
  value       = module.cluster.eks_cluster_arn
  description = "The Amazon Resource Name (ARN) of the EKS cluster."
}

output "eks_cluster_id" {
  value       = module.cluster.eks_cluster_id
  description = "EKS cluster name"
}

output "eks_cluster_oidc_issuer_url" {
  value       = module.cluster.eks_cluster_oidc_issuer_url
  description = "EKS cluster OIDC Issuer URL"
}

output "eks_cluster_oidc_provider_arn" {
  value       = module.cluster.eks_cluster_oidc_provider_arn
  description = "EKS cluster OIDC Provider ARN"
}

output "vpc-cni_iam_role_arn" {
  description = "vpc-cni EKS addon IRSA role ARN"
  value       = module.cluster.vpc-cni_iam_role_arn
}

output "vpc-cni_iam_role_name" {
  description = "vpc-cni EKS addon IRSA role name"
  value       = module.cluster.vpc-cni_iam_role_name
}

output "vpc-cni_iam_role_path" {
  description = "vpc-cni EKS addon IRSA role path"
  value       = module.cluster.vpc-cni_iam_role_path
}

output "vpc-cni_iam_role_unique_id" {
  description = "vpc-cni EKS addon IRSA role unique id"
  value       = module.cluster.vpc-cni_iam_role_unique_id
}
