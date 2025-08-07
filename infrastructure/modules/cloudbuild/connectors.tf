# Create a new Secret Manager secret if none provided
resource "google_secret_manager_secret" "github_token" {
  count     = var.github_token_secret_id == "" ? 1 : 0
  secret_id = "github-token"
  replication {
    user_managed {
      replicas {
        location = var.google_region
      }
    }
  }
}

# Create the initial version only when we created the secret
resource "google_secret_manager_secret_version" "github_token" {
  count       = var.github_token_secret_id == "" ? 1 : 0
  secret      = google_secret_manager_secret.github_token[0].id
  secret_data = var.github_token_secret_value
}

# Reference an existing secret if one was passed in
data "google_secret_manager_secret" "github_token" {
  count     = var.github_token_secret_id != "" ? 1 : 0
  secret_id = var.github_token_secret_id
  project   = var.google_project_id
}

# Get the latest version of the secret, regardless of how it was created
data "google_secret_manager_secret_version" "github_token_latest" {
  project = var.google_project_id
  secret  = var.github_token_secret_id == "" ? google_secret_manager_secret.github_token[0].secret_id : var.github_token_secret_id

  depends_on = [
    # If we created the secret, this data source should run after we create the initial version.
    google_secret_manager_secret_version.github_token
  ]
}

# Pick whichever secret we ended up with
locals {
  # Use the full resource ID for the secret for IAM.
  github_token_secret_id = var.github_token_secret_id == "" ? google_secret_manager_secret.github_token[0].id : data.google_secret_manager_secret.github_token[0].id

  # Use the full secret version ID for the Cloud Build connection.
  effective_oauth_token_secret_version = data.google_secret_manager_secret_version.github_token_latest.id
}

resource "google_secret_manager_secret_iam_member" "p4sa-secretAccessor" {
  for_each = toset([
    "serviceAccount:service-${var.google_project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com",
    "serviceAccount:${var.google_project_number}@cloudbuild.gserviceaccount.com"
  ])
  secret_id = local.github_token_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value
}

resource "google_cloudbuildv2_connection" "github" {
  project  = var.google_project_id
  location = var.google_region
  name     = "Github"
  disabled = false
  github_config {
    app_installation_id = var.github_google_cloud_build_installation_id
    authorizer_credential {
      oauth_token_secret_version = local.effective_oauth_token_secret_version
    }
  }
  depends_on = [google_secret_manager_secret_iam_member.p4sa-secretAccessor]
}

resource "google_cloudbuildv2_repository" "github_connection" {
  project           = var.google_project_id
  location          = var.google_region
  name              = var.connection_name == "" ? "default-repo-connection" : var.connection_name
  parent_connection = google_cloudbuildv2_connection.github.name
  remote_uri        = var.github_repository_uri
}
