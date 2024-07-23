// Secret Manager stores config data used by the Django API 
resource "google_project_service" "secretmanager" { //enable the secretmanager API. TODO: move to root module along with all other APIs 
  provider = google-beta
  service  = "secretmanager.googleapis.com"
  project  = var.project
}

// rest_application_settings stores DATABASE_URL (database connection string), GS_BUCKET_NAME (media bucket), SECRET_KEY (secret key used by Django for cryptographic signing of sessions and tokens)
resource "google_secret_manager_secret" "rest_application_settings" {
  provider  = google-beta
  project   = var.project 
  secret_id = "rest-application-settings"
  replication { //TODO: setup better replication
    auto {}
  }
  depends_on = [google_project_service.secretmanager]
}

resource "random_string" "secret_key" {
  length  = 50
  special = false
}


locals {
  database_url = "postgres://${google_sql_user.rest_db_user.name}:${google_sql_user.rest_db_user.password}@//cloudsql/${var.project}:${var.region}:${google_sql_database_instance.rest_db_instance.name}/${google_sql_database.rest_db_db.name}"
  depends_on   = [google_sql_user.rest_db_user, google_sql_database.rest_db_db]
}

resource "google_secret_manager_secret_version" "rest_application_settings_secret_version" {
  provider = google-beta
  secret   = google_secret_manager_secret.rest_application_settings.id
  secret_data = "DATABASE_URL=\"${local.database_url}\"\nGS_BUCKET_NAME=\"${google_storage_bucket.media_storage.name}\"\nSECRET_KEY=\"${random_string.secret_key.result}\""
  //ADD DEBUG=TRUE?? add feature flag?? 
  depends_on = [google_storage_bucket.media_storage]
}

resource "random_string" "django_superuser_pw" {
  length  = 30
  special = false
}


resource "google_secret_manager_secret" "django_superuser_pw_secret" {
  provider  = google-beta
  project   = var.project
  secret_id = "django_superuser_pw_secret"
  replication { //TODO: setup better replication
    auto {}
  }
  depends_on = [google_project_service.secretmanager]
}


resource "google_secret_manager_secret_version" "django_superuser_pw_secret_version" {
  provider    = google-beta
  secret      = google_secret_manager_secret.django_superuser_pw_secret.id
  secret_data = random_string.django_superuser_pw.result
}

