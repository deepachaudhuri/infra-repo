provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../aws-modules/vpc"

  name       = "test-vpc"
  cidr_block = "10.40.0.0/16"

  subnets = [
    {
      name              = "test-public-a"
      cidr_block        = "10.40.1.0/24"
      availability_zone = "us-east-1a"
      type              = "public"
    },
    {
      name              = "test-private-a"
      cidr_block        = "10.40.11.0/24"
      availability_zone = "us-east-1a"
      type              = "private"
    }
  ]

  create_internet_gateway = true
  enable_nat_gateway      = false

  tags = {
    Environment = "test"
    Project     = "lwplabs"
    ManagedBy   = "terraform"
  }
}
