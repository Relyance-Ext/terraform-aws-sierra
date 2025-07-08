module "vpc" {
  source = "./modules/vpc"
  count  = var.create_vpc_and_eks ? 1 : 0

  vpc_cidr        = var.vpc_cidr
  subnet_cidrs    = var.subnet_cidrs
  nat_subnet_cidr = var.nat_subnet_cidr
  default_tags    = local.default_tags
  base_name       = var.base_name
}
