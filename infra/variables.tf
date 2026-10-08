variable "aws_region" {
  type    = string
  default = "eu-north-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "artifact_bucket_name" {
  type = string
}

variable "allowed_http_cidr" {
  type    = string
  default = "0.0.0.0/0"
}
