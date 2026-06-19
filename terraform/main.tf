module "networking" {
  source = "./modules/networking"

  project_name             = var.project_name
  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
}

module "security_groups" {
  source = "./modules/security-groups"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  alb_ingress_cidrs = var.alb_ingress_cidrs
  app_port          = var.app_port
  rds_port          = var.rds_port
}

module "iam" {
  source = "./modules/iam"

  project_name                    = var.project_name
  environment                     = var.environment
  poster_bucket_name              = var.poster_bucket_name
  booking_notifications_queue_arn = aws_sqs_queue.booking_notifications.arn
}

module "compute" {
  source = "./modules/compute"

  project_name                  = var.project_name
  environment                   = var.environment
  aws_region                    = var.aws_region
  vpc_id                        = module.networking.vpc_id
  public_subnet_ids             = module.networking.public_subnet_ids
  private_app_subnet_ids        = module.networking.private_app_subnet_ids
  alb_security_group_id         = module.security_groups.alb_security_group_id
  private_alb_security_group_id = module.security_groups.private_alb_security_group_id
  ec2_app_security_group_id     = module.security_groups.ec2_app_security_group_id
  ec2_instance_profile_name     = module.iam.ec2_instance_profile_name
  ec2_instance_type             = var.ec2_instance_type
  ec2_key_name                  = var.ec2_key_name
  ecr_image_tag                 = var.ecr_image_tag
  app_config_secret_arn         = aws_secretsmanager_secret.app_config.arn
  poster_bucket_name            = var.poster_bucket_name
  poster_cdn_domain             = aws_cloudfront_distribution.posters.domain_name

  depends_on = [aws_secretsmanager_secret_version.app_config]
}
