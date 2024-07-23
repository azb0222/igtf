// STORAGE BUCKET FOR STATIC ASSETS
resource "random_string" "bucket_suffix" {
  length  = 5
  special = false
  upper = false 
}

resource "google_storage_bucket" "media_storage" {
  name                        = "rest-backend-media-storage-${random_string.bucket_suffix.result}"
  location                    = "US"
  uniform_bucket_level_access = false

}
