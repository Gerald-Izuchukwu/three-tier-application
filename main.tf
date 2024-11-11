module "vpc_network" {
  source     = "./modules/vpc"
  env_prefix = var.env_prefix
  avail_zone = var.avail_zone
  vpc_cidr   = var.vpc_cidr
}

module "security_groups" {
  source        = "./modules/security_groups"
  my_ip_address = var.my_ip_address
  vpc_id        = module.vpc_network.vpc.id
}

module "web_servers" {
  source                    = "./modules/webserver"
  S3ReadAndSSManagerProfile = var.S3ReadAndSSManagerProfile
  public_key_path           = var.public_key_path
  private_key_path          = var.private_key_path
  instance_type             = var.instance_type
  image_id                  = var.image_id
  env_prefix                = var.env_prefix
  external_lb_sg            = module.security_groups.external_lb_sg.id
  webserverSG               = module.security_groups.webserverSG.id
  vpc_id                    = module.vpc_network.vpc.id
  public_subnet             = module.vpc_network.public_subnet
}

module "app_servers" {
  source                    = "./modules/appserver"
  S3ReadAndSSManagerProfile = var.S3ReadAndSSManagerProfile
  public_key_path           = var.public_key_path
  private_key_path          = var.private_key_path
  instance_type             = var.instance_type
  image_id                  = var.image_id# echo "DATABASE=testdb" | sudo tee -a /etc/environment
  env_prefix                = var.env_prefix
  private_subnet            = module.vpc_network.private_subnet
  vpc_id                    = module.vpc_network.vpc.id
  internal_lb_sg            = module.security_groups.internal_lb_sg.id
  key_name                  = module.web_servers.key_name
  appserverSG               = module.security_groups.appserverSG.id
}


# ///OUTPUT the details you will use for db connection and put it in the db instance so it can be used to retieved and used to connect to db in the app instances
# # # module "db_servers" {
# # #   source               = "./modules/rds"
# # #   db_instance_username = var.db_instance_username
# # #   db_instance_password = var.db_instance_password
# # #   avail_zone           = var.avail_zone
# # #   dbserverSG           = module.security_groups.dbserverSG.id
# # #   db_subnet_group      = module.vpc_network.database_subnet
# # # }