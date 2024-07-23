resource "google_sql_database_instance" "rest_db_instance" {
  name             = "rest-db-instance"
  database_version = "POSTGRES_15"
  region           = var.region 

  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_database" "rest_db_db" {
  name     = "rest-db-db"
  instance = google_sql_database_instance.rest_db_instance.name
}

resource "google_sql_user" "rest_db_user" {
  name     = "djuser"
  instance = google_sql_database_instance.rest_db_instance.name
  password = "password" #TODO: auto generate, switch to using service account similar to other configuration  
}
