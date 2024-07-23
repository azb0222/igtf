resource "google_service_account" "rest_cloudrun_sa" {
  account_id = "rest-cloudrun-sa"
}

// Django API in Cloud Run should be able to connect to the database 
resource "google_project_iam_member" "rest_cloudrun_sa_act_as" {
  project = var.project
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.rest_cloudrun_sa.email}"
}

// Django API in Cloud Run should be able to access the static assets 
resource "google_project_iam_member" "rest_cloudrun_sa_storage_bucket" {
  project = var.project
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.rest_cloudrun_sa.email}"
}

// Django API in Cloud Run should be able to access the application settings in GCP secrets 
resource "google_project_iam_member" "rest_cloudrun_sa_secret_access" {
  project = var.project
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.rest_cloudrun_sa.email}"
}

// TODO: cloud build 

// cloud run jobs 
resource "google_cloud_run_v2_job" "rest_db_migrate" {
  name     = "rest-db-migrate"
  location = var.region

  template {
    template {
      volumes {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [google_sql_database_instance.rest_db_instance.connection_name]
        }
      }
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.rest_repo.name}/rest-api:latest"
        env {
          name = "APPLICATION_SETTINGS"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.rest_application_settings.secret_id
              version = "latest"
            }
          }
        }
        command = ["migrate"]
      }
      service_account = google_service_account.rest_cloudrun_sa.email
    }
  }
  depends_on = [google_secret_manager_secret.rest_application_settings]
}

//  Cloud SQL Admin API  TODO: YOU HAVE TO MAKE SURE THIS API IS ENABLED, DO THROUGH TF?
//gcloud run jobs execute migrate --region us-central1 --wait

resource "google_cloud_run_v2_job" "rest_db_createuser" {
  name     = "rest-db-createuser"
  location = var.region
  template {
    template {
      volumes {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [google_sql_database_instance.rest_db_instance.connection_name]
        }

      }
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.rest_repo.name}/rest-api:latest"
        env {
          name = "APPLICATION_SETTINGS"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.rest_application_settings.secret_id
              version = "latest"
            }
          }
        }
        env {
          name = "DJANGO_SUPERUSER_PASSWORD"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.django_superuser_pw_secret.secret_id
              version = "latest"
            }
          }
        }
        command = ["createuser"]
      }
      service_account = google_service_account.rest_cloudrun_sa.email
    }
  }
  depends_on = [google_secret_manager_secret.rest_application_settings, google_secret_manager_secret.django_superuser_pw_secret]
}




resource "google_cloud_run_v2_service" "rest_cr" {
  name     = "rest-cr-service"
  location = var.region
  template {
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.rest_db_instance.connection_name]
      }
    }
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.rest_repo.name}/rest-api:latest"
      env {
        name = "APPLICATION_SETTINGS"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.rest_application_settings.secret_id
            version = "latest"
          }
        }
      }
      env { 
        name = "DEBUG"
        value = "True"
      }
    }
    service_account = google_service_account.rest_cloudrun_sa.email
  }
  depends_on = [google_secret_manager_secret.rest_application_settings]
}


resource "google_cloud_run_service_iam_binding" "res_cr_iam" {
  location = google_cloud_run_v2_service.rest_cr.location
  service  = google_cloud_run_v2_service.rest_cr.name
  role     = "roles/run.invoker"
  members = [
    "allUsers"
  ]
}
