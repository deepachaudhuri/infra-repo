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
      name              = "dev-private-a"
      cidr_block        = "10.40.11.0/24"
      availability_zone = "us-east-1a"
      type              = "private"
    }
  ]

  create_internet_gateway = true
  enable_nat_gateway      = false

  tags = {
    Environment = "dev"
    Project     = "lwplabs"
    ManagedBy   = "terraform"
  }
}
