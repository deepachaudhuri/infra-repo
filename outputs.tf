output "vpc_id" {
  description = "The ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "subnet_ids" {
  description = "The subnet IDs created by the module"
  value       = module.vpc.subnet_ids
}

output "private_subnet_ids" {
  description = "The private subnet IDs created by the module"
  value       = module.vpc.private_subnet_ids
}

## this is commented when I'll be running next
# output "eks_cluster_id" {
#   description = "The ID/name of the EKS cluster"
#   value       = module.eks.cluster_id
# }

# output "eks_cluster_endpoint" {
#   description = "Endpoint for your EKS API server"
#   value       = module.eks.cluster_endpoint
# }

# output "eks_cluster_version" {
#   description = "The Kubernetes server version for the cluster"
#   value       = module.eks.cluster_version
# }

# output "eks_oidc_provider_arn" {
#   description = "ARN of the OIDC Provider for IRSA"
#   value       = module.eks.oidc_provider_arn
# }

# output "configure_kubectl" {
#   description = "Command to configure kubectl"
#   value       = module.eks.configure_kubectl_command
# }
