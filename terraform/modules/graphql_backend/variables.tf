variable "project" {
  description = "project ID"
  type        = string
}

variable "gcp_vpc_id" {
  description = "google vpc id"
  type        = string
}

variable "region" {
  description = "region"
  type        = string
}

variable "db_private_ip_subnet" {
  description = "The /24 subnet that will be used to communicate with the managed sql database. This should just be an IP address."
  type = string
}

variable "serverless_ip_subnet" {
  description = "The subnet that will be used to communicate with the serverless cloud function. This should be a /28 subnet."
  type = string
}

variable "db_name" {
  description = "The name of the database"
  type=string
}