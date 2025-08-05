data "google_iam_policy" "p4sa-secretAccessor" {
  binding {
    role = "roles/secretmanager.secretAccessor"
    members = [
      "serviceAccount:service-${var.google_project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com",
      "serviceAccount:${var.google_project_number}@cloudbuild.gserviceaccount.com"
    ]
  }
}

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
  secret_data = ""
}

# Reference an existing secret if one was passed in
data "google_secret_manager_secret" "github_token" {
  count     = var.github_token_secret_id != "" ? 1 : 0
  secret_id = var.github_token_secret_id
  project   = var.google_project_id
}

# Pick whichever secret we ended up with
locals {
  github_token_secret_id = var.github_token_secret_id == "" ? google_secret_manager_secret.github_token[0].id : data.google_secret_manager_secret.github_token[0].id
}

resource "google_secret_manager_secret_iam_policy" "policy" {
  secret_id   = var.github_token_secret_id
  policy_data = data.google_iam_policy.p4sa-secretAccessor.policy_data
}

resource "google_cloudbuildv2_connection" "github" {
  project  = var.google_project_id
  location = var.google_region
  name     = "Github"
  disabled = false
  github_config {
    app_installation_id = var.github_google_cloud_build_installation_id
    authorizer_credential {
      oauth_token_secret_version = var.github_token_secret_id
    }
  }
  depends_on = [google_secret_manager_secret_iam_policy.policy]
}

resource "google_cloudbuildv2_repository" "github_connection" {
  project           = var.google_project_id
  location          = var.google_region
  name              = var.connection_name == "" ? "default-repo-connection" : var.connection_name
  parent_connection = google_cloudbuildv2_connection.github.name
  remote_uri        = var.github_repository_uri
}
