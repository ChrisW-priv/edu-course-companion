# -------------------------------------------------------------------------------------
# API ENABLEMENT
# Enables necessary Google Cloud APIs for the application.
# -------------------------------------------------------------------------------------

resource "google_project_service" "service" {
  for_each = toset([
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com",
    "vpcaccess.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "eventarc.googleapis.com",
    "pubsub.googleapis.com",
  ])

  project            = var.google_project_id
  service            = each.value
  disable_on_destroy = false
}


resource "google_secret_manager_secret" "ai_api_key_secret" {
  depends_on = [
    google_project_service.service
  ]
  count     = var.ai_token_secret_id == "" ? 1 : 0
  project   = var.google_project_id
  secret_id = "ai-api-key-secret"

  replication {
    user_managed {
      replicas {
        location = var.google_region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "ai_api_key_version" {
  count       = var.ai_token_secret_id == "" ? 1 : 0
  secret      = google_secret_manager_secret.ai_api_key_secret[0].id
  secret_data = var.ai_api_key
}

locals {
  effective_ai_token_secret_id = var.ai_token_secret_id != "" ? var.ai_token_secret_id : google_secret_manager_secret.ai_api_key_secret[0].secret_id
  db_username                  = "postgres"
}

# -------------------------------------------------------------------------------------
# VPC Network
# Creates a VPC network and subnetwork for private connectivity.
# -------------------------------------------------------------------------------------
module "vpc_network" {
  depends_on = [
    google_project_service.service
  ]
  source                   = "./modules/vpc-network"
  google_project_id        = var.google_project_id
  google_region            = var.google_region
  network_name             = "main-vpc-network"
  subnetwork_name          = "main-subnetwork"
  subnetwork_ip_cidr_range = "10.0.0.0/20" # Adjust this CIDR range if needed
}

# module "cloudsql_postgres" {
#   depends_on = [
#     google_project_service.service,
#     module.vpc_network # Add dependency on VPC network module
#   ]
#   source                = "./modules/cloudsql-postgres"
#   google_project_id     = var.google_project_id
#   google_region         = var.google_region
#   instance_name         = "main-db-priv-instance"
#   db_user               = local.db_username
#   db_password_secret_id = var.db_password_secret_id
#   database_name         = "postgres"
#   vpc_network           = module.vpc_network.network_self_link # Link VPC to Cloud SQL
# }

# -------------------------------------------------------------------------------------
# VERTEX AI MODULE
# Enables necessary Google Cloud APIs for Vertex AI, Vertex Search, and Mistral OCR.
# -------------------------------------------------------------------------------------
module "vertex_ai" {
  depends_on = [
    google_project_service.service
  ]
  source            = "./modules/vertex-ai"
  google_project_id = var.google_project_id
  google_region     = var.google_region
}

module "file-processor" {
  depends_on = [
    google_project_service.service
  ]
  source                      = "./modules/file-processor"
  google_project_id           = var.google_project_id
  google_project_number       = var.google_project_number
  google_region               = var.google_region
  cloudrun_application_name   = "main"
  existing_output_bucket_name = module.cloudrun-application.django_uploads_bucket_name
  existing_input_bucket_name  = module.cloudrun-application.django_uploads_bucket_name
  service_account_email       = module.cloudrun-application.cloudrun_service_account_email
}

module "cloudbuild" {
  depends_on = [
    google_project_service.service
  ]
  source                                    = "./modules/cloudbuild"
  google_project_id                         = var.google_project_id
  google_project_number                     = var.google_project_number
  google_region                             = var.google_region
  github_google_cloud_build_installation_id = var.github_google_cloud_build_installation_id
  github_repository_uri                     = var.github_repository_uri
  github_token_secret_value                 = var.github_token_secret_value
}

module "cloudrun-application" {
  depends_on = [
    google_project_service.service,
    module.cloudbuild
  ]
  source                              = "./modules/cloudrun-application"
  google_project_id                   = var.google_project_id
  google_project_number               = var.google_project_number
  google_region                       = var.google_region
  cloudrun_application_name           = "main"
  django_superuser_password_secret_id = var.django_superuser_secret_id
  django_secret_key_secret_id         = var.django_secret_key_secret_id
  database_type                       = "sqlite3"
  docker_image_url                    = "${module.cloudbuild.artifact_registry_url}/${module.cloudbuild.image_name}:latest"
  postgres_username                   = local.db_username
  # cloudsql_connection_name            = module.cloudsql_postgres.instance_connection_name
  # postgres_password_secret_id         = module.cloudsql_postgres.db_password_secret_id # Use the secret ID output from cloudsql_postgres

  extra_env_vars = [
    {
      name      = var.ai_api_key_env_var_name
      secret_id = local.effective_ai_token_secret_id
    }
  ]
}
