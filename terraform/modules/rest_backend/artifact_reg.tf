// ARTIFACT REGISTRY
resource "google_artifact_registry_repository" "rest_repo" {
  location      = var.region  
  repository_id = "rest-repo"
  description   = "Rest Backend App Docker Images Repository"
  format        = "DOCKER"
}