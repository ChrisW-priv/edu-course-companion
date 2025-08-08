locals {
  # service-account creation flag & email
  is_creating_pubsub_sa        = var.pubsub_service_account_email == ""
  pubsub_service_account_email = local.is_creating_pubsub_sa ? google_service_account.pubsub_sa[0].email : var.pubsub_service_account_email
}

# service account
resource "google_service_account" "pubsub_sa" {
  count        = local.is_creating_pubsub_sa ? 1 : 0
  account_id   = "eventarc-workflows-sa"
  display_name = "Eventarc Workflows Service Account"
}

# allow SA to read from input bucket
resource "google_storage_bucket_iam_member" "input_sa_viewer" {
  bucket = var.existing_input_bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${local.pubsub_service_account_email}"
}

resource "google_project_iam_member" "workflowsinvoker" {
  for_each = toset([
    "roles/workflows.invoker",
    "roles/eventarc.eventReceiver",
    "roles/logging.logWriter",
  ])
  project = var.google_project_id
  role    = each.value
  member  = "serviceAccount:${local.pubsub_service_account_email}"
}

data "google_storage_project_service_account" "gcs_account" {}
resource "google_project_iam_member" "pubsubpublisher" {
  project = var.google_project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

# Cloud Run
resource "google_cloud_run_v2_service" "extractor" {
  name                = "${var.cloudrun_application_name}-extractor-service"
  project             = var.google_project_id
  location            = var.google_region
  deletion_protection = false

  template {
    service_account = var.service_account_email

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    # mount both buckets via GCS volumes
    volumes {
      name = "input-bucket"
      gcs { bucket = var.existing_input_bucket_name }
    }
    volumes {
      name = "output-bucket"
      gcs { bucket = var.existing_output_bucket_name }
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
  }
}

# Let Eventarc’s service agent invoke the Cloud Run service
resource "google_cloud_run_service_iam_member" "eventarc_invoker" {
  service  = google_cloud_run_v2_service.extractor.name
  location = var.google_region
  role     = "roles/run.invoker"
  member   = "serviceAccount:${local.pubsub_service_account_email}"
}

# ─────────────────────────────── Eventarc permissions fix ─────────────────────────────────
# Give the SA permission to receive events
resource "google_project_iam_member" "sa_eventarc_receiver" {
  project    = var.google_project_id
  role       = "roles/eventarc.eventReceiver"
  member     = "serviceAccount:${var.service_account_email}"
  depends_on = [var.service_account_email]
}

# ───────────────────────────────────── Eventarc trigger ────────────────────────────────────
resource "google_eventarc_trigger" "on_input_finalized" {
  name     = "trigger-storage-cloudrun-tf"
  project  = var.google_project_id
  location = var.google_region
  depends_on = [
    google_cloud_run_v2_service.extractor,
    google_project_iam_member.sa_eventarc_receiver,
    google_project_iam_member.pubsubpublisher,
  ]

  # Cloud Storage finalized objects in the input bucket
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }
  matching_criteria {
    attribute = "bucket"
    value     = var.existing_input_bucket_name
  }

  destination {
    cloud_run_service {
      service = google_cloud_run_v2_service.extractor.id
      region  = var.google_region
    }
  }

  service_account = local.pubsub_service_account_email
}
