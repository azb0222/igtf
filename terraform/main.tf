data "google_organization" "ingenius" {
  domain = "ingenius.studio"
}

data "google_billing_account" "asritha_ba" {
  billing_account = "010D12-54F779-3473F3"
  open            = true
}

data "google_project" "dev" {
  project_id = var.dev_project_id
}

module "rest_backend" {
  source  = "./modules/rest_backend"
  region  = var.region
  project = data.google_project.dev.project_id
}

module "frontend" {
  source         = "./modules/frontend"
  region         = var.region
  project        = data.google_project.dev.project_id #TODO: is this the best way to do this 
  project_number = data.google_project.dev.number
}

module "graphql_backend" {
  source               = "./modules/graphql_backend"
  region               = var.region
  project              = data.google_project.dev.project_id
  gcp_vpc_id           = data.google_compute_network.default_vpc.id
  db_private_ip_subnet = "10.100.0.0"
  db_name              = "graphql-db"
  serverless_ip_subnet = "10.100.1.0/28"
}

/*
todo: automate these all later

steps to setup: 
1) manually authenticate github repo with cloud run service
2) start cloud build trigger to generate the inital image
3) update the container name in the job and create job 
4) run job 
5) run cloud build trigger again to now run the cloud run 
*/

output "test" {
  value = module.frontend.test
}
