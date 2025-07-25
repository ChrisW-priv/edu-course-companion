resource "google_sql_database_instance" "main_instance" {
  database_version = "POSTGRES_15"
  name             = var.instance_name
  project          = var.google_project_id
  region           = var.google_region

  settings {
    tier = var.instance_tier
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_network
    }
  }
}

# -------------------------------------------------------------------------------------
# FEATURE: Secret Manager Secrets for Database Credentials
# Creates new Secret Manager secrets for the database user and password,
# or references an existing one based on `db_password_secret_id`.
# -------------------------------------------------------------------------------------

resource "google_secret_manager_secret" "db_password_secret" {
  count     = var.db_password_secret_id == "" ? 1 : 0
  project   = var.google_project_id
  secret_id = "${var.instance_name}-db-password"

  replication {
    user_managed {
      replicas {
        location = var.google_region
      }
    }
  }
}

resource "random_password" "db_password" {
  count  = var.db_password_secret_id == "" ? 1 : 0
  length = 32
}

resource "google_secret_manager_secret_version" "db_password_version" {
  count       = var.db_password_secret_id == "" ? 1 : 0
  secret      = google_secret_manager_secret.db_password_secret[0].id
  secret_data = random_password.db_password[0].result
  depends_on  = [google_secret_manager_secret.db_password_secret[0]]
}

data "google_secret_manager_secret_version" "existing_db_password_version" {
  count   = var.db_password_secret_id != "" ? 1 : 0
  secret  = var.db_password_secret_id
  version = "latest"
}


locals {
  effective_db_password_secret_id = var.db_password_secret_id != "" ? var.db_password_secret_id : google_secret_manager_secret.db_password_secret[0].secret_id
  effective_db_password           = var.db_password_secret_id != "" ? data.google_secret_manager_secret_version.existing_db_password_version[0].secret_data : random_password.db_password[0].result
}

resource "google_sql_user" "admin_user" {
  name     = var.db_user
  instance = google_sql_database_instance.main_instance.name
  project  = var.google_project_id
  password = local.effective_db_password
}
