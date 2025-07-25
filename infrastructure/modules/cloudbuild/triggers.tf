# -------------------------------------------------------------------------------------
# FEATURE: Service Account for Cloud Build
# Creates a new IAM Service Account or references an existing one.
# -------------------------------------------------------------------------------------

variable "cloud_build_service_account_name" {
  description = "Base name to use when creating a new Cloud Build service account."
  type        = string
  default     = "cloud-build-service-account"
}

# Create new SA when cloud_build_service_account_id is empty
resource "google_service_account" "created_sa" {
  count        = var.cloud_build_service_account_id == "" ? 1 : 0
  account_id   = "${var.cloud_build_service_account_name}-sa"
  display_name = "Cloud Build Service Account for ${var.cloud_build_service_account_name}"
  project      = var.google_project_id
}

# Reference existing SA when cloud_build_service_account_id is set
data "google_service_account" "existing_sa" {
  count      = var.cloud_build_service_account_id != "" ? 1 : 0
  account_id = var.cloud_build_service_account_id
  project    = var.google_project_id
}

locals {
  cloud_build_service_account_email = var.cloud_build_service_account_id == "" ? google_service_account.created_sa[0].email : data.google_service_account.existing_sa[0].email
}

# --------------------------------------------------------------------------
# Cloud Build Trigger
# --------------------------------------------------------------------------
resource "google_cloudbuild_trigger" "github_backend_trigger" {
  name            = "deploy-main-backend"
  location        = "europe-west3"
  description     = "Trigger to build and deploy the backend code on main branch"
  service_account = local.cloud_build_service_account_email

  repository_event_config {
    repository = google_cloudbuildv2_repository.github_connection.id
    push {
      branch = "^main$"
    }
  }

  git_file_source {
    path       = "./backend/cloudbuild.yaml"
    repo_type  = "GITHUB"
    repository = google_cloudbuildv2_repository.github_connection.id
    revision   = "refs/heads/main"
  }

  source_to_build {
    uri       = var.github_repository_uri
    ref       = "refs/heads/main"
    repo_type = "GITHUB"
  }

  substitutions = {
    "_IMAGE"                 = "backend"
    "_ARTIFACT_REGISTRY_URL" = var.artifact_registry_url
  }
}
