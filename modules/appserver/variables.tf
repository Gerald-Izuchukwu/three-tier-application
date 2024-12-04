variable "S3ReadAndSSManagerProfile" {}
variable "public_key_path" {
  description = "Path to the ssh public key file"
  type        = string
}
variable "private_key_path" {}
variable "instance_type" {}
variable "image_id" {}
variable "env_prefix" {}
variable "internal_lb_sg" {}
variable "private_subnet" {}
variable "vpc_id" {}
variable "appserverSG" {}