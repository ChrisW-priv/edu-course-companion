# -------------------------------------------------------------------------------------
# FEATURE: Service Account for Cloud Run
# Creates a new IAM Service Account or references an existing one.
# -------------------------------------------------------------------------------------

resource "google_service_account" "created_sa" {
  count        = var.service_account_email == "" ? 1 : 0
  account_id   = "${var.cloudrun_application_name}-cloudrun-sa"
  display_name = "Cloud Run Service Account for ${var.cloudrun_application_name}"
  project      = var.google_project_id
}

data "google_service_account" "existing_sa" {
  count      = var.service_account_email != "" ? 1 : 0
  account_id = var.service_account_email
}

locals {
  cloudrun_service_account = {
    email = var.service_account_email == "" ? google_service_account.created_sa[0].email : data.google_service_account.existing_sa[0].email
  }
}

# ------------------------------------------------------------------------------------
# FEATURE: Django Superuser Password Secret Management
# Generates a new password and creates a Secret Manager secret, or references
# an existing one.
# ------------------------------------------------------------------------------------

resource "google_secret_manager_secret" "django_superuser_password_secret" {
  count     = var.django_superuser_password_secret_id == "" ? 1 : 0
  project   = var.google_project_id
  secret_id = "${var.cloudrun_application_name}-django-superuser-password"

  replication {
    user_managed {
      replicas {
        location = var.google_region
      }
    }
  }
}

resource "random_password" "django_superuser_password" {
  count  = var.django_superuser_password_secret_id == "" ? 1 : 0
  length = 32
}

resource "google_secret_manager_secret_version" "django_superuser_password_version" {
  count       = var.django_superuser_password_secret_id == "" ? 1 : 0
  secret      = google_secret_manager_secret.django_superuser_password_secret[0].id
  secret_data = random_password.django_superuser_password[0].result
  depends_on  = [google_secret_manager_secret.django_superuser_password_secret]
}

locals {
  effective_django_superuser_password_secret_id = var.django_superuser_password_secret_id != "" ? var.django_superuser_password_secret_id : google_secret_manager_secret.django_superuser_password_secret[0].secret_id
}

# ------------------------------------------------------------------------------------
# FEATURE: Django Secret Key Secret Management
# Generates a new secret key and creates a Secret Manager secret, or references
# an existing one.
# ------------------------------------------------------------------------------------

resource "google_secret_manager_secret" "django_secret_key_secret" {
  count     = var.django_secret_key_secret_id == "" ? 1 : 0
  project   = var.google_project_id
  secret_id = "${var.cloudrun_application_name}-django-secret-key"

  replication {
    user_managed {
      replicas {
        location = var.google_region
      }
    }
  }
}

resource "random_string" "django_secret_key" {
  count            = var.django_secret_key_secret_id == "" ? 1 : 0
  length           = 50
  special          = true
  override_special = "!@#$%^&*()-_=+" # Django requires specific characters
}

resource "google_secret_manager_secret_version" "django_secret_key_version" {
  count       = var.django_secret_key_secret_id == "" ? 1 : 0
  secret      = google_secret_manager_secret.django_secret_key_secret[0].id
  secret_data = random_string.django_secret_key[0].result
  depends_on  = [google_secret_manager_secret.django_secret_key_secret]
}

locals {
  effective_django_secret_key_secret_id = var.django_secret_key_secret_id != "" ? var.django_secret_key_secret_id : google_secret_manager_secret.django_secret_key_secret[0].secret_id
}

# -------------------------------------------------------------------------------------
# FEATURE: Google Cloud Storage Buckets
# Creates new GCS buckets or references existing ones based on variables.
# -------------------------------------------------------------------------------------

locals {
  is_creating_statics_bucket = var.existing_statics_bucket_name == ""
  is_creating_uploads_bucket = var.existing_uploads_bucket_name == ""
}

resource "google_storage_bucket" "created_statics" {
  count         = local.is_creating_statics_bucket ? 1 : 0
  name          = "${var.cloudrun_application_name}-statics"
  location      = var.google_region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "created_uploads" {
  count         = local.is_creating_uploads_bucket ? 1 : 0
  name          = "${var.cloudrun_application_name}-uploads"
  location      = var.google_region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
}

data "google_storage_bucket" "existing_statics" {
  count = !local.is_creating_statics_bucket ? 1 : 0
  name  = var.existing_statics_bucket_name
}

data "google_storage_bucket" "existing_uploads" {
  count = !local.is_creating_uploads_bucket ? 1 : 0
  name  = var.existing_uploads_bucket_name
}

locals {
  statics_bucket_name = local.is_creating_statics_bucket ? google_storage_bucket.created_statics[0].name : data.google_storage_bucket.existing_statics[0].name
  uploads_bucket_name = local.is_creating_uploads_bucket ? google_storage_bucket.created_uploads[0].name : data.google_storage_bucket.existing_uploads[0].name
}

# -------------------------------------------------------------------------------------
# FEATURE: IAM for Secret Manager Secrets
# Grant the Cloud Run service account permissions to access required secrets.
# -------------------------------------------------------------------------------------

resource "google_secret_manager_secret_iam_member" "django_superuser_password_secret_accessor" {
  secret_id = local.effective_django_superuser_password_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.cloudrun_service_account.email}"
}

resource "google_secret_manager_secret_iam_member" "django_secret_key_secret_accessor" {
  secret_id = local.effective_django_secret_key_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.cloudrun_service_account.email}"
}

resource "google_secret_manager_secret_iam_member" "postgres_password_secret_accessor" {
  count     = var.database_type == "postgres" && var.postgres_password_secret_id != "" ? 1 : 0
  secret_id = var.postgres_password_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.cloudrun_service_account.email}"
}

resource "google_secret_manager_secret_iam_member" "ai_api_key_secret_accessor" {
  count     = var.ai_token_secret_id != "" ? 1 : 0
  secret_id = var.ai_token_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.cloudrun_service_account.email}"
}

resource "google_secret_manager_secret_iam_member" "extra_env_var_secret_accessor" {
  for_each  = { for ev in var.extra_env_vars : ev.name => ev if ev.secret_id != null }
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.cloudrun_service_account.email}"
}

# -------------------------------------------------------------------------------------
# FEATURE: IAM for GCS Buckets
# Grant the service account permissions to the GCS buckets.
# -------------------------------------------------------------------------------------

resource "google_storage_bucket_iam_member" "statics_viewer_all_users" {
  bucket = local.statics_bucket_name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_storage_bucket_iam_member" "statics_admin_sa" {
  bucket = local.statics_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${local.cloudrun_service_account.email}"
}

resource "google_storage_bucket_iam_member" "uploads_admin_sa" {
  bucket = local.uploads_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${local.cloudrun_service_account.email}"
}

# -------------------------------------------------------------------------------------
# FEATURE: Cloud Run Service
# -------------------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "application_backend" {
  name                = var.cloudrun_application_name
  project             = var.google_project_id
  location            = var.google_region
  deletion_protection = false

  lifecycle {
    ignore_changes = [template[0].containers[0].image]
  }

  template {
    service_account = local.cloudrun_service_account.email

    scaling {
      min_instance_count = var.min_instance_count
      max_instance_count = var.max_instance_count
    }

    volumes {
      name = "private-bucket-volume"
      gcs {
        bucket = local.uploads_bucket_name
      }
    }

    volumes {
      name = "public-bucket-volume"
      gcs {
        bucket = local.statics_bucket_name
      }
    }

    dynamic "volumes" {
      for_each = var.database_type == "postgres" ? [1] : []
      content {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [var.cloudsql_connection_name]
        }
      }
    }

    containers {
      name  = "django"
      image = var.docker_image_url

      ports {
        name           = "h2c"
        container_port = 8080
      }

      volume_mounts {
        name       = "private-bucket-volume"
        mount_path = "/app/data/private"
      }

      volume_mounts {
        name       = "public-bucket-volume"
        mount_path = "/app/data/public"
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      # Common environment variables from original backend-service.tf
      env {
        name  = "LOGGING_USE_CLOUD_HANDLER"
        value = "false"
      }

      env {
        name  = "LOGGING_OTLP_ENABLE_SPANS"
        value = "true"
      }

      env {
        name  = "DATABASE_TYPE_ENV"
        value = var.database_type
      }

      dynamic "env" {
        for_each = var.database_type == "postgres" ? [1] : []
        content {
          name  = "DB_CONN_NAME"
          value = var.cloudsql_connection_name
        }
      }

      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = var.google_project_id
      }

      env {
        name  = "LOGGING_OTLP_URL"
        value = "http://127.0.0.1"
      }

      env {
        name  = "STATIC_BUCKET_NAME"
        value = local.statics_bucket_name
      }

      env {
        name  = "UPLOAD_BUCKET_NAME"
        value = local.uploads_bucket_name
      }

      dynamic "env" {
        for_each = var.database_type == "sqlite3" ? [1] : []
        content {
          name  = "DATABASE_URL"
          value = "sqlite:////app/data/private/database.sqlite3"
        }
      }

      env {
        name  = "DEPLOYMENT_ENVIRONMENT"
        value = "PRODUCTION"
      }

      env {
        name  = "DEPLOYMENT_TARGET"
        value = "GCP_DOCKER"
      }

      dynamic "env" {
        for_each = var.database_type == "postgres" ? [1] : []
        content {
          name  = "POSTGRES_USER"
          value = var.postgres_username
        }
      }

      dynamic "env" {
        for_each = var.database_type == "postgres" ? [1] : []
        content {
          name = "POSTGRES_PASSWORD"
          value_source {
            secret_key_ref {
              secret  = var.postgres_password_secret_id
              version = "latest"
            }
          }
        }
      }

      env {
        name = "DJANGO_SUPERUSER_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = local.effective_django_superuser_password_secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "DJANGO_SECRET_KEY"
        value_source {
          secret_key_ref {
            secret  = local.effective_django_secret_key_secret_id
            version = "latest"
          }
        }
      }

      # Extra environment variables with direct values
      dynamic "env" {
        for_each = [for ev in var.extra_env_vars : ev if ev.secret_id == null]
        content {
          name  = env.value.name
          value = env.value.value
        }
      }

      # Extra environment variables from Secret Manager
      dynamic "env" {
        for_each = [for ev in var.extra_env_vars : ev if ev.secret_id != null]
        content {
          name = env.value.name
          value_source {
            secret_key_ref {
              secret  = env.value.secret_id
              version = env.value.secret_version != null ? env.value.secret_version : "latest"
            }
          }
        }
      }
    }

    # Jaeger container (optional, based on your previous config)
    dynamic "containers" {
      for_each = var.include_jaeger_container ? [1] : []
      content {
        name  = "jaeger"
        image = "jaegertracing/all-in-one:latest"

        env {
          name  = "COLLECTOR_OTLP_ENABLED"
          value = "true"
        }

        env {
          name  = "QUERY_BASE_PATH"
          value = "/jaeger"
        }

        env {
          name  = "LOG_LEVEL"
          value = "info"
        }
      }
    }
  }
}

# -------------------------------------------------------------------------------------
# FEATURE: Cloud Run SETUP Job
# -------------------------------------------------------------------------------------

data "google_iam_policy" "jobs-secretAccessor" {
  binding {
    role    = "roles/secretmanager.secretAccessor"
    members = ["serviceAccount:${local.cloudrun_service_account.email}"]
  }
}

locals {
  non_null_secret_ids = concat(
    [
      local.effective_django_secret_key_secret_id,
      local.effective_django_superuser_password_secret_id
    ],
    var.postgres_password_secret_id != "" ? [var.postgres_password_secret_id] : [],
  )
}

resource "google_secret_manager_secret_iam_policy" "policy" {
  for_each    = toset(local.non_null_secret_ids)
  secret_id   = each.key
  policy_data = data.google_iam_policy.jobs-secretAccessor.policy_data
}

resource "google_cloud_run_v2_job" "backend_setup_job" {
  name                = "backend-setup"
  project             = var.google_project_id
  location            = var.google_region
  deletion_protection = false

  template {
    template {
      service_account = local.cloudrun_service_account.email

      max_retries = 0
      volumes {
        name = "private-bucket-volume"
        gcs {
          bucket = local.uploads_bucket_name
        }
      }

      volumes {
        name = "public-bucket-volume"
        gcs {
          bucket = local.statics_bucket_name
        }
      }

      dynamic "volumes" {
        for_each = var.database_type == "postgres" ? [1] : []
        content {
          name = "cloudsql"
          cloud_sql_instance {
            instances = [var.cloudsql_connection_name]
          }
        }
      }

      containers {
        image = var.docker_image_url
        resources {
          limits = {
            "memory" = "1Gi"
          }
        }
        volume_mounts {
          name       = "private-bucket-volume"
          mount_path = "/app/data/private"
        }
        volume_mounts {
          name       = "public-bucket-volume"
          mount_path = "/app/data/public"
        }
        dynamic "volume_mounts" {
          for_each = var.database_type == "postgres" ? [1] : []
          content {
            name       = "cloudsql"
            mount_path = "/cloudsql"
          }
        }
        command = ["/bin/bash"]
        args    = ["-c", "./entrypoint.sh setup"]

        env {
          name = "DJANGO_SECRET_KEY"
          value_source {
            secret_key_ref {
              secret  = local.effective_django_secret_key_secret_id
              version = "latest"
            }
          }
        }

        dynamic "env" {
          for_each = var.database_type == "postgres" ? [1] : []
          content {
            name = "POSTGRES_PASSWORD"
            value_source {
              secret_key_ref {
                secret  = var.postgres_password_secret_id
                version = "latest"
              }
            }
          }
        }

        env {
          name = "DJANGO_SUPERUSER_PASSWORD"
          value_source {
            secret_key_ref {
              secret  = local.effective_django_superuser_password_secret_id
              version = "latest"
            }
          }
        }

        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = var.google_project_id
        }

        env {
          name  = "UPLOAD_BUCKET_NAME"
          value = local.uploads_bucket_name
        }

        env {
          name  = "STATIC_BUCKET_NAME"
          value = local.statics_bucket_name
        }

        env {
          name  = "DEPLOYMENT_ENVIRONMENT"
          value = "PRODUCTION"
        }

        env {
          name  = "DEPLOYMENT_TARGET"
          value = "GCP_DOCKER"
        }

        env {
          name  = "DATABASE_TYPE_ENV"
          value = var.database_type
        }

        dynamic "env" {
          for_each = var.database_type == "postgres" ? [1] : []
          content {
            name  = "DB_CONN_NAME"
            value = var.cloudsql_connection_name
          }
        }

        dynamic "env" {
          for_each = var.database_type == "sqlite3" ? [1] : []
          content {
            name  = "DATABASE_URL"
            value = "sqlite:////app/data/private/database.sqlite3"
          }
        }

        dynamic "env" {
          for_each = var.database_type == "postgres" ? [1] : []
          content {
            name  = "POSTGRES_USER"
            value = var.postgres_username
          }
        }
      }
    }
  }
}
