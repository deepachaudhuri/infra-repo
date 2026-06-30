output "vpc_id" {
  description = "The ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "subnet_ids" {
  description = "The subnet IDs created by the module"
  value       = module.vpc.subnet_ids
}
