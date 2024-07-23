# data "google_storage_bucket" "tf_state" {
#   name = var.dev_state_bucket 
# }

terraform {
  backend "gcs" {
    bucket = "dev-ingenius-app-173049-tf-state"
    prefix = "terraform/state"
  }
}
