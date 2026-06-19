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
  booking_notifications_queue_arn = module.data.booking_notifications_queue_arn
}

module "data" {
  source = "./modules/data"

  project_name           = var.project_name
  environment            = var.environment
  private_db_subnet_ids  = module.networking.private_db_subnet_ids
  rds_security_group_id  = module.security_groups.rds_security_group_id
  db_name                = var.db_name
  db_username            = var.db_username
  db_instance_class      = var.db_instance_class
  db_allocated_storage   = var.db_allocated_storage
  db_password            = var.db_password
  rds_port               = var.rds_port
  jwt_secret             = var.jwt_secret
  internal_service_token = var.internal_service_token
  admin_email            = var.admin_email
  admin_password         = var.admin_password
  user_email             = var.user_email
  user_password          = var.user_password
  poster_bucket_name     = var.poster_bucket_name
  notification_email     = var.notification_email
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
  app_config_secret_arn         = module.data.app_config_secret_arn
  poster_bucket_name            = var.poster_bucket_name
  poster_cdn_domain             = module.data.poster_cloudfront_domain_name

  depends_on = [module.data]
}

module "observability" {
  source = "./modules/observability"

  project_name                      = var.project_name
  environment                       = var.environment
  aws_region                        = var.aws_region
  account_id                        = module.compute.account_id
  public_alb_arn                    = module.compute.alb_arn
  public_alb_arn_suffix             = module.compute.alb_arn_suffix
  private_alb_arn_suffix            = module.compute.private_alb_arn_suffix
  autoscaling_group_name            = module.compute.autoscaling_group_name
  rds_instance_identifier           = module.data.rds_instance_identifier
  lambda_function_name              = module.data.booking_notification_lambda_name
  sqs_queue_name                    = module.data.booking_notifications_queue_name
  sns_topic_arn                     = module.data.booking_notifications_sns_topic_arn
  poster_cloudfront_distribution_id = module.data.poster_cloudfront_distribution_id
  poster_bucket_arn                 = module.data.poster_bucket_arn
}
