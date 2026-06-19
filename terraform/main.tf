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
