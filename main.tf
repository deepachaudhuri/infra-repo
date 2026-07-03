provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "git::https://github.com/deepachaudhuri/aws-modules.git//vpc?ref=master"

  name       = "dev-vpc"
  cidr_block = "10.40.0.0/16"

  subnets = [
    {
      name              = "dev-public-a"
      cidr_block        = "10.40.1.0/24"
      availability_zone = "us-east-1a"
      type              = "public"
    },
    {
      name              = "dev-public-b"
      cidr_block        = "10.40.2.0/24"
      availability_zone = "us-east-1b"
      type              = "public"
    },
    {
      name              = "dev-private-a"
      cidr_block        = "10.40.11.0/24"
      availability_zone = "us-east-1a"
      type              = "private"
    },
    {
      name              = "dev-private-b"
      cidr_block        = "10.40.12.0/24"
      availability_zone = "us-east-1b"
      type              = "private"
    }
  ]

  create_internet_gateway = true
  enable_nat_gateway      = true

  tags = {
    Environment = "dev"
    Project     = "test3"
    ManagedBy   = "terraform"
  }
}

module "eks" {
  source = "git::https://github.com/deepachaudhuri/aws-modules.git//eks?ref=master"

  cluster_name       = "dev-eks-cluster"
  kubernetes_version = "1.34"
  subnet_ids         = module.vpc.private_subnet_ids

  node_groups = [
    {
      name           = "general"
      subnet_ids     = module.vpc.private_subnet_ids
      desired_size   = 2
      min_size       = 1
      max_size       = 4
      instance_types = ["t3.medium"]
      disk_size      = 20
    }
  ]

  enable_aws_load_balancer_controller = true
  enable_ebs_csi_driver               = true
  enable_efs_csi_driver               = true
  enable_cloudwatch_observability     = true

  tags = {
    Environment = "dev"
    Project     = "lwplabs3"
    ManagedBy   = "terraform"
  }

  depends_on = [module.vpc]
}
