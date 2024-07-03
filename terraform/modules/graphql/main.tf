// POSTGRESQL DB

// allocates /24 subnet of internal IP addresses 
resource "google_compute_global_address" "graphql_db_private_ip"{
  provider = google-beta
  project = var.project 
  name          = "graphql-db-private-ip"
  purpose       = "VPC_PEERING" //allows private IPs from different VPCs to communicate w/ each other
  address_type  = "INTERNAL" 
  prefix_length = 24
  address       = "10.100.0.0" 
  network       = var.gcp_vpc_id 
}

// establish VPC Network Peering connection between own VPC and GCP VPC
resource "google_service_networking_connection" "graphql_db_private_vpc_connection" { 
  provider = google-beta
  network                 = var.gcp_vpc_id 
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.graphql_db_private_ip.name]
}

resource "google_sql_database_instance" "graphql_db" {
  name             = "graphqldb" 
  database_version = "POSTGRES_15"
  region           = var.region 

  depends_on = [google_service_networking_connection.graphql_db_private_vpc_connection]

  settings {
    tier = "db-f1-micro" 
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.gcp_vpc_id 
      enable_private_path_for_google_cloud_services = true
      //TODO: check this over
      ssl_mode = "ENCRYPTED_ONLY"
      # require_ssl = true
    } 
  }
  deletion_protection = false
}

// TODO: do we need this? format properly
# output "ctf_db_private_ip"{ 
#   value = google_sql_database_instance.ctf_db.private_ip_address
# }