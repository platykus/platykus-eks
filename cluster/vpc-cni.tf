module "vpc-cni" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.2.0"

  attach_vpc_cni_policy = true
  oidc_providers        = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
  role_description    = "IRSA role for vpc-cni in ${module.eks.cluster_id} cluster"
  role_name           = "${module.eks.cluster_id}.irsa.vpc-cni"
  vpc_cni_enable_ipv6 = true
  tags                = var.tags
}

output "vpc-cni_iam_role_arn" {
  description = "vpc-cni EKS addon IRSA role ARN"
  value       = module.vpc-cni.iam_role_arn
}

output "vpc-cni_iam_role_name" {
  description = "vpc-cni EKS addon IRSA role name"
  value       = module.vpc-cni.iam_role_name
}

output "vpc-cni_iam_role_path" {
  description = "vpc-cni EKS addon IRSA role path"
  value       = module.vpc-cni.iam_role_path
}

output "vpc-cni_iam_role_unique_id" {
  description = "vpc-cni EKS addon IRSA role unique id"
  value       = module.vpc-cni.iam_role_unique_id
}
