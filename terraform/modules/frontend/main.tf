// ARTIFACT REGISTRY REPOSITORY 
resource "google_artifact_registry_repository" "frontend_repo" {
  location      = var.region
  repository_id = "frontend-repo"
  description   = "Frontend App Docker Images Repository"
  format        = "DOCKER"
}

// CLOUD RUN
resource "google_cloud_run_v2_service" "frontend_cr" {
  name     = "frontend-cr-service"
  location = var.region
  # ingress  = "INGRESS_TRAFFIC_ALL"
  template {
    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello" //TODO: everytime you do terraform apply, it overwrites, pull directly from this, check if image exists, otherwise pull, update 
    }
  }
}

resource "google_cloud_run_service_iam_binding" "frontend_cr_iam" {
  location = google_cloud_run_v2_service.frontend_cr.location
  service  = google_cloud_run_v2_service.frontend_cr.name
  role     = "roles/run.invoker"
  members = [
    "allUsers"
  ]
}

// CLOUD BUILD
resource "google_service_account" "cloudbuild_sa" {
  account_id = "cloudbuild-sa"
}

resource "google_project_iam_member" "cloudbuild_sa_act_as" {
  project = var.project 
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloudbuild_sa.email}"
}

// TODO: still getting:  The service account running this build does not have permission to write logs. To fix this, grant the Logs Writer (roles/logging.logWriter) role to the service account. 
resource "google_project_iam_member" "cloudbuild_sa_logs_writer" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloudbuild_sa.email}"
}

resource "google_project_iam_member" "cloudbuild_sa_push_to_ar" {
  project = var.project
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${google_service_account.cloudbuild_sa.email}"
}

resource "google_project_iam_member" "cloudbuild_sa_run_cloud_run" {
  project = var.project
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.cloudbuild_sa.email}"
}

resource "google_cloudbuild_trigger" "frontend_cloudbuild_trigger" {
  location = var.region

  trigger_template {
    branch_name = "main"
    repo_name   = "ingenius-frontend" // in the GCP console, the cloudbuild_trigger must be manually authenticated with the ingenius-frontend Github repo after running `terraform apply`
  }

  service_account = google_service_account.cloudbuild_sa.id
  depends_on = [
    google_project_iam_member.cloudbuild_sa_act_as,
    google_project_iam_member.cloudbuild_sa_logs_writer,
    google_project_iam_member.cloudbuild_sa_push_to_ar,
    google_project_iam_member.cloudbuild_sa_run_cloud_run,
  ]

  build {
    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["build", "-t", "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.frontend_repo.name}/frontend", "."]
    }
    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["push", "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.frontend_repo.name}/frontend"]
    }
    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = ["run", "deploy", "${google_cloud_run_v2_service.frontend_cr.name}", "--image", "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.frontend_repo.name}/frontend", "--region", "${var.region}", "--platform", "managed", "--allow-unauthenticated"]
    }
    options {
      logging = "CLOUD_LOGGING_ONLY"
    }
  }
}
