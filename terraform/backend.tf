resource "google_storage_bucket" "tf_state" {
  name          = "ingenius-app-state"
  location      = var.region
  force_destroy = true
  storage_class = "STANDARD"

  depends_on = [google_project.dev]
  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true
}


terraform { 
    backend "gcs" { 
        bucket = "ingenius-app-state" 
        prefix = "terraform/state"
    }
}
