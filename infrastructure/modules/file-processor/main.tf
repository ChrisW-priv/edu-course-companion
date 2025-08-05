locals {
  # bucket creation flags
  is_creating_input_bucket  = var.existing_input_bucket_name == ""
  is_creating_output_bucket = var.existing_output_bucket_name == ""

  # final bucket names
  input_bucket_name = local.is_creating_input_bucket ? "${var.cloudrun_application_name}-input" : var.existing_input_bucket_name

  output_bucket_name = local.is_creating_output_bucket ? "${var.cloudrun_application_name}-output" : var.existing_output_bucket_name

  # service‐account creation flag & email
  is_creating_sa        = var.service_account_email == ""
  service_account_email = local.is_creating_sa ? google_service_account.this[0].email : var.service_account_email


}

# create or reference input bucket
resource "google_storage_bucket" "created_input" {
  count                       = local.is_creating_input_bucket ? 1 : 0
  name                        = local.input_bucket_name
  location                    = var.google_region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "created_output" {
  count                       = local.is_creating_output_bucket ? 1 : 0
  name                        = local.output_bucket_name
  location                    = var.google_region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
}

data "google_storage_bucket" "existing_input" {
  count = local.is_creating_input_bucket ? 0 : 1
  name  = var.existing_input_bucket_name
}

data "google_storage_bucket" "existing_output" {
  count = local.is_creating_output_bucket ? 0 : 1
  name  = var.existing_output_bucket_name
}

# Conditionally create the SA
resource "google_service_account" "this" {
  count        = local.is_creating_sa ? 1 : 0
  account_id   = "${var.cloudrun_application_name}-file-processor-sa"
  display_name = "${var.cloudrun_application_name} service account"
}

# Grant the SA objectViewer on input bucket
resource "google_storage_bucket_iam_member" "input_sa_reader" {
  bucket = local.input_bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${local.service_account_email}"
}

# Grant the SA objectCreator on output bucket
resource "google_storage_bucket_iam_member" "output_sa_writer" {
  bucket = local.output_bucket_name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${local.service_account_email}"
}



# Cloud Run Job definition
resource "google_cloud_run_v2_job" "extractor" {
  name     = "${var.cloudrun_application_name}-extractor-job"
  project  = var.google_project_id
  location = var.google_region

  template {
    task_count = 1

    template {
      # mount both buckets via GCS volumes
      volumes {
        name = "input-bucket"
        gcs {
          bucket = local.input_bucket_name
        }
      }
      volumes {
        name = "output-bucket"
        gcs {
          bucket = local.output_bucket_name
        }
      }

      containers {
        image = var.docker_image_url

        volume_mounts {
          name       = "input-bucket"
          mount_path = var.input_mount_path
        }
        volume_mounts {
          name       = "output-bucket"
          mount_path = var.output_mount_path
        }
      }

      # use our SA (created or provided)
      service_account = local.service_account_email
    }
  }
}

# Eventarc trigger on new GCS objects
resource "google_eventarc_trigger" "on_input_finalized" {
  name       = "${var.cloudrun_application_name}-trigger"
  project    = var.google_project_id
  location   = var.google_region
  depends_on = [google_cloud_run_v2_job.extractor]

  # filter finalization events in your input prefix
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }
  matching_criteria {
    attribute = "bucket"
    value     = local.input_bucket_name
  }

  destination {
    cloud_run_service {
      service = google_cloud_run_v2_job.extractor.name
      region  = var.google_region
    }
  }

  service_account = var.service_account_email
}
