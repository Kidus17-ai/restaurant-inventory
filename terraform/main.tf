# Read secrets from SSM Parameter Store
data "aws_ssm_parameter" "db_password" {
  name            = "/restockiq/production/db_password"
  with_decryption = true
}

data "aws_ssm_parameter" "secret_key" {
  name            = "/restockiq/production/secret_key"
  with_decryption = true
}

# Locals — computed values used throughout
locals {
  # Standard name prefix for all resources
  name_prefix = format("%s-%s", var.app_name, var.environment)

  # Common tags applied to every resource
  common_tags = {
    Project     = var.app_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "kidus"
  }

  # Database connection URL built from components
  db_url = format(
    "postgresql://%s:%s@%s/%s",
    var.db_username,
    data.aws_ssm_parameter.db_password.value,
    module.rds.db_endpoint,
    "restockiq_production"
  )

  # ECS task config looked up from map variable
  ecs_cpu    = lookup(var.ecs_task_config, var.environment).cpu
  ecs_memory = lookup(var.ecs_task_config, var.environment).memory

  # DB instance class looked up from map variable
  db_instance_class = lookup(var.db_instance_class, var.environment)
}

# VPC Module
module "vpc" {
  source             = "./modules/vpc"
  name_prefix        = local.name_prefix
  availability_zones = var.availability_zones
  common_tags        = local.common_tags
}

# RDS Module
module "rds" {
  source                     = "./modules/rds"
  name_prefix                = local.name_prefix
  db_username                = var.db_username
  db_password                = data.aws_ssm_parameter.db_password.value
  db_name                    = var.db_name
  db_instance_class          = local.db_instance_class
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  ecs_security_group_id      = module.ecs.ecs_security_group_id
  enable_deletion_protection = var.enable_deletion_protection
  common_tags                = local.common_tags
}

# ECS Module
module "ecs" {
  source      = "./modules/ecs"
  name_prefix = local.name_prefix
  app_name    = var.app_name
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.public_subnet_ids
  app_port    = var.app_port
  app_count   = var.app_count
  cpu         = local.ecs_cpu
  memory      = local.ecs_memory
  db_url      = local.db_url
  secret_key  = data.aws_ssm_parameter.secret_key.value
  common_tags = local.common_tags
  alert_email = "kidusermiyas6@gmail.com"
}

# Route53 Module
module "route53" {
  source       = "./modules/route53"
  domain_name  = var.domain_name
  alb_dns_name = module.ecs.alb_dns_name
  alb_zone_id  = module.ecs.alb_zone_id
  common_tags  = local.common_tags
  acm_certificate_arn = "arn:aws:acm:us-east-1:810772959098:certificate/dcc84266-96f1-4815-83f4-0ec89d2a5cab"
}