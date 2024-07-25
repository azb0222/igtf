// ARTIFACT REGISTRY REPOSITORY 
# resource "google_artifact_registry_repository" "graphql_repo" {
#   location      = var.region
#   repository_id = "graphql-repo"
#   description   = "GraphQL Docker Images Repository"
#   format        = "DOCKER"
# }
#
# // CLOUD BUILD
# resource "google_service_account" "graphql_cloudbuild_sa" {
#   account_id = "graphql-cloudbuild-sa"
# }
#
# resource "google_project_iam_member" "graphql_cloudbuild_sa_act_as" {
#   project = var.project
#   role    = "roles/iam.serviceAccountUser"
#   member  = "serviceAccount:${google_service_account.graphql_cloudbuild_sa.email}"
# } // TODO: can configure https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudbuild_trigger#example-usage---cloudbuild-trigger-repo Cloud Build Trigger Repo
#
# resource "google_project_iam_member" "graphql_cloudbuild_sa_logs_writer" {
#   project = var.project
#   role    = "roles/logging.logWriter"
#   member  = "serviceAccount:${google_service_account.graphql_cloudbuild_sa.email}"
# }
#
#
# resource "google_project_iam_member" "graphql_cloudbuild_sa_push_to_ar" {
#   project = var.project
#   role    = "roles/artifactregistry.writer"
#   member  = "serviceAccount:${google_service_account.graphql_cloudbuild_sa.email}"
# }
#
#
# resource "google_project_iam_member" "graphql_cloudbuild_sa_run_cloud_run" {
#   project = var.project
#   role    = "roles/run.admin"
#   member  = "serviceAccount:${google_service_account.graphql_cloudbuild_sa.email}"
# }
#
# resource "google_project_iam_member" "graphql_cloudbuild_sa_admin" {
#   project = var.project
#   role    = "roles/artifactregistry.admin"
#   member  = "serviceAccount:${google_service_account.graphql_cloudbuild_sa.email}"
# }
#
# // CLOUD BUILD
#
# resource "google_cloudbuild_trigger" "graphql_cloudbuild_trigger" {
#   name     = "ingenius-graphql-build"
#   location = var.region
#
#   trigger_template {
#     branch_name = "main"
#     repo_name   = "ingenius-graphql" // in the GCP console, the cloudbuild_trigger must be manually authenticated with the ingenius-frontend Github repo after running `terraform apply`
#   }
#
#   service_account = google_service_account.graphql_cloudbuild_sa.id
#   depends_on = [
#     google_project_iam_member.graphql_cloudbuild_sa_act_as,
#     google_project_iam_member.graphql_cloudbuild_sa_logs_writer,
#     google_project_iam_member.graphql_cloudbuild_sa_push_to_ar,
#     google_project_iam_member.graphql_cloudbuild_sa_run_cloud_run,
#     google_project_iam_member.graphql_cloudbuild_sa_admin,
#   ]
#
#   build {
#     timeout = "2400s"
#     step {
#       name = "gcr.io/cloud-builders/docker"
#       args = ["build", "-t", "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.graphql_repo.name}/graphqlapi:latest", "."]
#     }
#     step {
#       name    = "gcr.io/cloud-builders/docker"
#       args    = ["push", "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.graphql_repo.name}/graphqlapi:latest"]
#       timeout = "1200s"
#     }
#     # i also idk if i need debug=true in the dockerfile
#     step {
#       name = "gcr.io/cloud-builders/gcloud"
#       args = ["run", "deploy", "${google_cloud_run_v2_service.graphql_cr.name}", "--image", "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.graphql_repo.name}/graphqlapi:latest", "--region", "${var.region}", "--platform", "managed", "--allow-unauthenticated"]
#     }
#     #TODO: run the cloud build graphql_cr_db_migrate_job
#     options {
#       logging = "CLOUD_LOGGING_ONLY"
#     }
#   }
# }


// POSTGRES 
# resource "google_sql_database_instance" "graphql_db_instance" {
#   name             = "graphql-db-instance"
#   database_version = "POSTGRES_15"
#   region           = var.region
#
#   settings {
#     tier = "db-f1-micro"
#   }
# }
#
# resource "google_sql_user" "graphql_db_user" {
#   name     = "admin"
#   instance = google_sql_database_instance.graphql_db_instance.name
#   password = "password" ##TODO: move to secret manager, auto generate instead
# }

// CLOUD RUN SERVICE
resource "google_cloud_run_v2_service" "graphql_cr" {
  name     = "graphql-cr-service"
  location = "us-central1"
  # ingress  = "INGRESS_TRAFFIC_ALL"
  template {
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.graphql_db_instance.connection_name]
      }
    }
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.graphql_repo.name}/graphqlapi:latest"

      #   image = "us-docker.pkg.dev/cloudrun/container/hello" //TODO: everytime you do terraform apply, it overwrites, pull directly from this, check if image exists, otherwise pull, update
      #TODO: fix dependency issue 
      env {
        name  = "DATABASE_URL"
        value = "postgresql://${google_sql_user.graphql_db_user.name}:${google_sql_user.graphql_db_user.password}@localhost/mydb?host=/cloudsql/${var.project}:${var.region}:${google_sql_database_instance.graphql_db_instance.name}"
      }
      env {
        name  = "AUTH_SECRET"
        value = "test"
      }
      env {
        name  = "APP_PASSWORD_RESET_SECRET"
        value = "test"
      }
      volume_mounts { //TODO: i dont even think i need this volume mount ... or do i for the connection string shit ... make sure i actually understand wtf is going on here 
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }
    service_account = google_service_account.graphql_cr_job_sa.email
  }
}
//NOW DONE through cloud build 
# resource "google_cloud_run_service_iam_binding" "graphql_cr_iam" {
#   location = google_cloud_run_v2_service.graphql_cr.location
#   service  = google_cloud_run_v2_service.graphql_cr.name
#   role     = "roles/run.invoker"
#   members = [
#     "allUsers"
#   ]
#   // publically available for now TODO: fix
# }

// CLOUD RUN JOB
# resource "google_service_account" "graphql_cr_job_sa" {
#   account_id = "graphql-cloudrun-job-sa"
# }

# resource "google_project_iam_member" "graphql_cr_job_sa_act_as" {
#   project = var.project
#   role    = "roles/iam.serviceAccountUser"
#   member  = "serviceAccount:${google_service_account.graphql_cr_job_sa.email}"
# }


# resource "google_project_iam_member" "graphql_cr_job_sa_logs_writer" {
#   project = var.project
#   role    = "roles/iam.serviceAccountUser"
#   member  = "serviceAccount:${google_service_account.graphql_cr_job_sa.email}"
# }



# resource "google_project_iam_member" "graphql_cr_job_sa_sql_client" {
#   project = var.project
#   role    = "roles/cloudsql.client"
#   member  = "serviceAccount:${google_service_account.graphql_cr_job_sa.email}"
# }

# resource "google_project_iam_member" "graphql_cr_job_sa_artifact_admin" {
#   project = var.project
#   role    = "roles/artifactregistry.admin"
#   member  = "serviceAccount:${google_service_account.graphql_cr_job_sa.email}"
# }


resource "google_cloud_run_v2_job" "graphql_cr_db_migrate_job" {
  name     = "graphql-cr-db-migrate-job"
  location = var.region

  template {
    template {
      volumes {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [google_sql_database_instance.graphql_db_instance.connection_name]
        }
      }
      containers {
        # image = "us-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.graphql_repo.name}/graphqlapi" //TODO
        image = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.graphql_repo.name}/graphqlapi:latest"
        args  = ["npx", "prisma", "migrate", "deploy"]
        env {
          //TODO use cloud secret manager
          name  = "DATABASE_URL"
          value = "postgresql://${google_sql_user.graphql_db_user.name}:${google_sql_user.graphql_db_user.password}@localhost/mydb?host=/cloudsql/${var.project}:${var.region}:${google_sql_database_instance.graphql_db_instance.name}"
        }
        volume_mounts {
          name       = "cloudsql"
          mount_path = "/cloudsql"
        }
      }
      service_account = google_service_account.graphql_cr_job_sa.email
    }
  }

  //TODO: needs Cloud SQL Admin API to work 
  depends_on = [google_sql_database_instance.graphql_db_instance, google_sql_user.graphql_db_user]
}
