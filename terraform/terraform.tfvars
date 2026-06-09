aws_region   = "us-east-1"
project_name = "blacktickets"
environment  = "dev"
vpc_cidr     = "10.0.0.0/16"

public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24"]
private_app_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
private_db_subnet_cidrs  = ["10.0.21.0/24", "10.0.22.0/24"]

alb_ingress_cidrs = ["0.0.0.0/0"]
app_port          = 80
rds_port          = 5432

ec2_instance_type     = "t3.small"
ec2_key_name          = null
ecr_image_tag         = "latest"
alb_health_check_path = "/"

db_name              = "identity_db"
db_username          = "postgres"
db_instance_class    = "db.t4g.micro"
db_allocated_storage = 20


admin_email            = "admin@blacktickets.com"
admin_password         = "Admin@12345"

user_email             = "user@blacktickets.com"
user_password          = "User@12345"

db_password            = "BlackTicketsDB123!"

jwt_secret             = "MyVeryLongJWTSecretForBlackTickets2026"

internal_service_token = "InternalServiceToken2026"