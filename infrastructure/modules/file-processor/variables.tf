variable "google_project_id" {
  type        = string
  description = "GCP project to deploy into"
}

variable "google_project_number" {
  type        = string
  description = "GCP project number to deploy into"
}

variable "google_region" {
  type        = string
  description = "GCP region"
}

variable "cloudrun_application_name" {
  type        = string
  description = "Base name for all resources (buckets, job, trigger, etc.)"
}

variable "existing_input_bucket_name" {
  type        = string
  description = "If non-empty, use this bucket instead of creating a new one for inputs"
}

variable "existing_output_bucket_name" {
  type        = string
  description = "If non-empty, use this bucket instead of creating a new one for outputs"
}

variable "input_prefix" {
  type        = string
  description = "GCS object name prefix to watch (e.g. \"watched-dir/\")"
  default     = "/"
}

variable "input_mount_path" {
  type        = string
  default     = "/app/data/in"
  description = "Container path where the input bucket is mounted"
}

variable "output_mount_path" {
  type        = string
  default     = "/app/data/out"
  description = "Container path where the output bucket is mounted"
}

variable "input_directory" {
  type        = string
  description = "Subdirectory (under the mount) to read files from"
  default     = "/"
}

variable "output_directory" {
  type        = string
  description = "Subdirectory (under the mount) to write files to"
  default     = "/"
}

variable "docker_image_url" {
  description = "The URL of the Docker image to deploy to Cloud Run. If empty, a default 'hello-world' image is used."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "service_account_email" {
  description = "The email of an existing service account to be used for Cloud Run."
  type        = string
}

variable "pubsub_service_account_email" {
  description = "The email of an existing service account to be used for pubsub topics. If provided, creation is skipped and this existing account is used. If empty, a new service account with a default name based on application_name will be created."
  type        = string
  default     = ""
}

variable "pubsub_topic_name" {
  type        = string
  default     = ""
  description = "Pub/Sub topic name for Eventarc to publish into (default: <app>-eventarc-topic)"
}
