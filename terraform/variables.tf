# using type as reference is made from environment variable
# set as TF_VAR_varname = var 
# General gcp variables
variable "gcp_key" {
  type = string
}

variable "service_account" {
  type = string
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "location" {
  default = "EU"
}

# Compute instance variables
variable "ssh_user" {
  type = string
}

variable "ssh_key" {
  type = string
}

variable "ip_address" {
  type = string
}


variable "deployment_bucket_name" {
  type = string
}

variable "datalake_bucket_name" {
  type = string
}

variable "cloud_function_bucket_name" {
  type = string
}

variable "dataset_name" {
  type = string
}
