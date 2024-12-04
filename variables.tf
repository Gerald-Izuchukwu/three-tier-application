variable "env_prefix" {}
variable "avail_zone" {}
variable "vpc_cidr" {}
variable "my_ip_address" {}
variable "public_key_path" {
  description = "Path to the ssh public key file"
  type        = string
}
variable "private_key_path" {}
variable "instance_type" {}
variable "image_id" {}
variable "db_instance_password" {}
variable "db_instance_username" {}
variable "S3ReadAndSSManagerProfile" {}
variable "db_name" {}