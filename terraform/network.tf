data "google_compute_network" "default_vpc" {
  name = "default"
  project = var.dev_project_id
}
