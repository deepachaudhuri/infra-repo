module "vpc" {
  source = "git::https://github.com/deepachaudhuri/aws-modules.git//vpc?ref=master"

  name       = "lwplabs-vpc"
  cidr_block = "10.20.0.0/16"

  subnets = [
    {
      name              = "public-1"
      cidr_block        = "10.20.1.0/24"  ## 256 ip addresses
      availability_zone = "us-east-1a"
      type              = "public"
    },
    {
      name              = "public-2"
      cidr_block        = "10.20.2.0/24" ## 256 ip addresses
      availability_zone = "us-east-1b"
      type              = "public"
    },
    {
      name              = "private-1"
      cidr_block        = "10.20.3.0/24" ## 256 ip addresses
      availability_zone = "us-east-1a"
      type              = "private"
    },
    {
      name              = "private-2"
      cidr_block        = "10.20.4.0/24" ## 256 ip addresses
      availability_zone = "us-east-1b"
      type              = "private"
    }
  ]

  create_internet_gateway = true
  enable_nat_gateway      = true
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

module "eks" {
  source = "git::https://github.com/deepachaudhuri/aws-modules.git//eks?ref=master"

  cluster_name       = "lwplabs-cluster"
  kubernetes_version = "1.34"  # Latest EKS version
  subnet_ids         = module.vpc.private_subnet_ids

  node_groups = [
    {
      name           = "primary"
      subnet_ids     = module.vpc.private_subnet_ids
      desired_size   = 2
      min_size       = 1
      max_size       = 4
      instance_types = ["t3.medium"]
      disk_size      = 20
    }
  ]

  enable_aws_load_balancer_controller = false
  enable_ebs_csi_driver               = true
  enable_efs_csi_driver               = true
  enable_cloudwatch_observability     = true

  tags = {
    Environment = "dev"
    Project     = "lwplabs"
  }
}