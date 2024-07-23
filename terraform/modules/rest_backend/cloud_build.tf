
// CLOUD BUILD
// TODO: can configure https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudbuild_trigger#example-usage---cloudbuild-trigger-repo Cloud Build Trigger Repo 
resource "google_service_account" "rest_rest_cloudbuild_sa" {
  account_id = "rest-cloudbuild-sa"
}

resource "google_project_iam_member" "rest_cloudbuild_sa_act_as" {
  project = var.project
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.rest_rest_cloudbuild_sa.email}"
}

// TODO: still getting:  The service account running this build does not have permission to write logs. To fix this, grant the Logs Writer (roles/logging.logWriter) role to the service account. 
resource "google_project_iam_member" "rest_cloudbuild_sa_logs_writer" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.rest_rest_cloudbuild_sa.email}"
}

resource "google_project_iam_member" "rest_cloudbuild_sa_push_to_ar" {
  project = var.project
  role   = "roles/artifactregistry.writer"
  member = "serviceAccount:${google_service_account.rest_rest_cloudbuild_sa.email}"
}

// TODO: MAKE MORE GRANULAR, DEF DONT NEED ADMIN ALSO, check over 
resource "google_project_iam_member" "rest_cloudbuild_sa_admin" {
  project = var.project
  role   = "roles/artifactregistry.admin"
  member = "serviceAccount:${google_service_account.rest_rest_cloudbuild_sa.email}"
}

resource "google_project_iam_member" "rest_cloudbuild_sa_run_cloud_run" {
  project = var.project
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.rest_rest_cloudbuild_sa.email}"
}

# resource "google_cloudbuild_trigger" "rest_cloudbuild_trigger" {
#   name = "ingenius-rest-build"
#   location = var.region

#   trigger_template {
#     branch_name = "main"
#     repo_name   = "ingenius-rest" // in the GCP console, the cloudbuild_trigger must be manually authenticated with the ingenius-rest Github repo after running `terraform apply`
#   }

#   service_account = google_service_account.rest_rest_cloudbuild_sa.id
#   depends_on = [
#     google_project_iam_member.rest_cloudbuild_sa_act_as,
#     google_project_iam_member.rest_cloudbuild_sa_logs_writer,
#     google_project_iam_member.rest_cloudbuild_sa_push_to_ar,
#     google_project_iam_member.rest_cloudbuild_sa_run_cloud_run,
#     google_project_iam_member.rest_cloudbuild_sa_admin, 
#   ]

#   build {
#     timeout = "2400s"
#     step {
#       name = "gcr.io/cloud-builders/docker"
#       args = ["build", "-t", "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.rest_repo.name}/rest-api", "."]
#     }
#     step {
#       name = "gcr.io/cloud-builders/docker"
#       args = ["push", "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.rest_repo.name}/rest-api"]
#       timeout = "1200s"
#     }
#     #TODO: add deploy to cloud run service + job 

#     options {
#       logging = "CLOUD_LOGGING_ONLY"
#     }
#   }
# }



resource "google_cloudbuild_trigger" "rest_cloudbuild_trigger" {
  name = "ingenius-rest-build"
  location = var.region

  trigger_template {
    branch_name = "main"
    repo_name   = "ingenius-rest"
  }

   service_account = google_service_account.rest_rest_cloudbuild_sa.id
  depends_on = [
    google_project_iam_member.rest_cloudbuild_sa_act_as,
    google_project_iam_member.rest_cloudbuild_sa_logs_writer,
    google_project_iam_member.rest_cloudbuild_sa_push_to_ar,
    google_project_iam_member.rest_cloudbuild_sa_run_cloud_run,
    google_project_iam_member.rest_cloudbuild_sa_admin, 
  ]

  build {
    step {
      name = "gcr.io/k8s-skaffold/pack"
      args = [
        "build",
        "--builder", "gcr.io/buildpacks/builder:v1",
        "--path", ".",
        "--publish","${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.rest_repo.name}/rest-api"
      ]
    }

    images = ["${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.rest_repo.name}/rest-api"]


    options {
      logging = "CLOUD_LOGGING_ONLY"
    }
  }
  
}
