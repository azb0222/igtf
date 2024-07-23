
output test { 
  value = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.frontend_repo.name}/frontend"
}