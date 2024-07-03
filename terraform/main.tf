data "google_organization" "ingenius" {
  domain = "ingenius.studio"
}

data "google_billing_account" "asritha_ba" {
  billing_account = "0171C3-085B94-E5D89A"
  open            = true
}

resource "google_folder" "ingenius-app" {
  display_name = "ingenius-app"
  parent       = data.google_organization.ingenius.id
}

# resource "google_project" "dev" {
#   name                = "ingenius-app-dev"
#   project_id          = "ingenius-app-dev-env"
#   folder_id           = google_folder.ingenius-app.id
#   auto_create_network = false
#   lifecycle {
#     prevent_destroy = true
#   }
#   billing_account = data.google_billing_account.asritha_ba.id
# }

# resource "google_project" "prod" {
#   name                = "ingenius-app-prod"
#   project_id          = "ingenius-app-prod-env"
#   folder_id           = google_folder.ingenius-app.id
#   auto_create_network = false
#   lifecycle {
#     prevent_destroy = true
#   }
#   billing_account = data.google_billing_account.asritha_ba.id
# }

data "google_compute_network" "default_vpc" {
  name = "default"
}

# module "backend" {
#   source = "./modules/backend"
# }

module "frontend" {
  source         = "./modules/frontend"
  region         = var.region
  project        = google_project.dev.id
  project_number = google_project.dev.number
}

# module "graphql" {
#   source = "./modules/graphql"
#   region = var.region
#   project = google_project.dev.id
#   gcp_vpc_id = google_compute_network.default_vpc.id 
# }

