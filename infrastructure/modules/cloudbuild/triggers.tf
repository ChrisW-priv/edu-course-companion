# -------------------------------------------------------------------------------------
# FEATURE: Service Account for Cloud Build
# Creates a new IAM Service Account or references an existing one.
# -------------------------------------------------------------------------------------

# Create new SA when cloud_build_service_account_email is empty
resource "google_service_account" "created_sa" {
  count        = var.cloud_build_service_account_email == "" ? 1 : 0
  account_id   = "minimal-cloud-build-sa"
  display_name = "Minimaly privileged Service Account for Cloud Build"
}

# Grant roles to the created SA.
# These bindings are only created when a new SA is created by this module.
resource "google_project_iam_member" "cloud_build_sa_roles" {
  for_each = var.cloud_build_service_account_email == "" ? local.cloud_build_sa_roles : toset([])
  project  = var.google_project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.created_sa[0].email}"
}

# Reference existing SA when cloud_build_service_account_email is set
data "google_service_account" "existing_sa" {
  count      = var.cloud_build_service_account_email != "" ? 1 : 0
  account_id = var.cloud_build_service_account_email
  project    = var.google_project_id
}

locals {
  cloud_build_service_account_email = var.cloud_build_service_account_email == "" ? google_service_account.created_sa[0].email : data.google_service_account.existing_sa[0].email
  cloud_build_service_account_id    = var.cloud_build_service_account_email == "" ? google_service_account.created_sa[0].id : data.google_service_account.existing_sa[0].id

  cloud_build_sa_roles = toset([
    "roles/cloudbuild.builds.builder",
    "roles/artifactregistry.writer",
    "roles/logging.logWriter",
    "roles/secretmanager.secretAccessor",
    "roles/run.invoker",
    "roles/run.viewer",
    "roles/run.viewer",
    "roles/run.developer",
    "roles/cloudbuild.builds.editor",
    "roles/serviceusage.serviceUsageConsumer",
  ])
}

resource "google_service_account_iam_member" "cloud_build_can_act_as_compute" {
  service_account_id = "projects/${var.google_project_id}/serviceAccounts/${var.google_project_number}-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${local.cloud_build_service_account_email}"
}

# --------------------------------------------------------------------------
# Cloud Build Trigger
# --------------------------------------------------------------------------

locals {
  image_name = "backend"
}

resource "google_cloudbuild_trigger" "github_backend_trigger" {
  name            = "build-backend-main"
  location        = var.google_region
  project         = var.google_project_id
  description     = "Trigger to build the backend code on main branch"
  service_account = local.cloud_build_service_account_id

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
    "_IMAGE"                 = local.image_name
    "_ARTIFACT_REGISTRY_URL" = local.artifact_registry_url
  }
}
