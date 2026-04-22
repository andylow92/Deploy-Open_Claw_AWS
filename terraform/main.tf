locals {
  name_prefix = "${var.project_name}-${var.environment}"

  effective_key_name         = var.ssh_key_name != "" ? var.ssh_key_name : var.key_name
  effective_ssh_ingress_cidrs = var.enable_ssh ? (
    var.allowed_ssh_cidr != "" ? [var.allowed_ssh_cidr] : var.ssh_ingress_cidrs
  ) : []
}

module "network" {
  source = "./modules/network"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = var.enable_nat_gateway
}

module "security" {
  source = "./modules/security"

  name_prefix       = local.name_prefix
  vpc_id            = module.network.vpc_id
  ssh_ingress_cidrs = local.effective_ssh_ingress_cidrs
}

module "compute" {
  source = "./modules/compute"

  name_prefix              = local.name_prefix
  subnet_id                = module.network.public_subnet_ids[0]
  vpc_id                   = module.network.vpc_id
  security_group_ids       = [module.security.instance_sg_id]
  instance_type            = var.instance_type
  ami_id                   = var.ami_id
  key_name                 = local.effective_key_name
  public_key_path          = var.public_key_path
  ssh_user                 = var.ssh_user
  root_volume_size         = var.root_volume_size_gb
  instance_profile_name    = var.instance_profile_name
  additional_user_data     = var.additional_user_data
}
