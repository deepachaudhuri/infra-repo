module "vpc" {
  source = "git::https://github.com/deepachaudhuri/aws-modules.git//vpc?ref=master"

  name       = "lwplabs-vpc"
  cidr_block = "10.20.0.0/16"

  subnets = [
    {
      name              = "public-1"
      cidr_block        = "10.20.1.0/24"
      availability_zone = "us-east-1a"
      type              = "public"
    },
    {
      name              = "private-1"
      cidr_block        = "10.20.11.0/24"
      availability_zone = "us-east-1a"
      type              = "private"
    }
  ]

  create_internet_gateway = true
  enable_nat_gateway      = false
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}