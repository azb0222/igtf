variable "region" {
  description = "region"
  type        = string
  default     = "us-central1"
}

variable "dev_project_id" { 
  description = "dev project id"
  type = string 
}

variable "dev_project_name" { 
  description = "dev project name"
  type = string 
}

variable "dev_tf_state_bucket" { 
  description = "dev state bucket"
  type = string
}