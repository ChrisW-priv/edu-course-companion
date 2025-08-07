variable "google_project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "google_project_number" {
  description = "The GCP project number."
  type        = string
}

variable "google_region" {
  description = "The GCP region for deploying resources."
  type        = string
}

variable "cloudrun_application_name" {
  description = "The full name of the application (e.g., 'edu-course-companion')."
  type        = string
}

variable "cloudsql_connection_name" {
  description = "The connection name of the Cloud SQL instance (e.g., 'project:region:instance'). Required if database_type is 'postgres'."
  type        = string
  default     = null
}

variable "database_type" {
  description = "The type of database to use: 'postgres' for Cloud SQL PostgreSQL or 'sqlite3' for SQLite on GCS."
  type        = string
  default     = "postgres" # Default to postgres for backward compatibility
  validation {
    condition     = contains(["postgres", "sqlite3"], var.database_type)
    error_message = "The database_type must be either 'postgres' or 'sqlite3'."
  }
}

variable "docker_image_url" {
  description = "The URL of the Docker image to deploy to Cloud Run. If empty, a default 'hello-world' image is used."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "min_instance_count" {
  description = "Minimum number of Cloud Run instances."
  type        = number
  default     = 0
}

variable "max_instance_count" {
  description = "Maximum number of Cloud Run instances."
  type        = number
  default     = 1
}

variable "include_jaeger_container" {
  description = "Whether to include the Jaeger sidecar container for tracing."
  type        = bool
  default     = false
}

# --- Service Account Variable ---
variable "service_account_email" {
  description = "The email of an existing service account to be used for Cloud Run. If provided, creation is skipped and this existing account is used. If empty, a new service account with a default name based on application_name will be created."
  type        = string
  default     = ""
}

# --- GCS Bucket Variables (for create or reference) ---
variable "existing_statics_bucket_name" {
  description = "The name of an existing GCS bucket to use for Django static files. If empty, a new bucket will be created."
  type        = string
  default     = ""
}

variable "existing_uploads_bucket_name" {
  description = "The name of an existing GCS bucket to use for user uploaded files. If empty, a new bucket will be created."
  type        = string
  default     = ""
}


# --- Secret Manager Secret IDs (for optional referencing) ---
variable "ai_token_secret_id" {
  description = "The Secret Manager secret ID for the AI API token (e.g., OpenAI, Gemini). If provided, this takes precedence. If empty, 'ai_api_key' will be used."
  type        = string
  default     = ""
}

variable "ai_api_key" {
  description = "The direct value for the AI API token. Used if 'ai_token_secret_id' is empty."
  type        = string
  default     = ""
  sensitive   = true
}

variable "ai_api_key_env_var_name" {
  description = "The name of the environment variable to use for the AI API key in the Cloud Run container."
  type        = string
  default     = "AI_API_KEY"
}

variable "postgres_username" {
  description = "The username for the PostgreSQL database. Required if database_type is 'postgres'."
  type        = string
  default     = "postgres"
}

variable "postgres_password_secret_id" {
  description = "The Secret Manager secret ID for the PostgreSQL password. Required if database_type is 'postgres'."
  type        = string
  default     = ""
}

variable "django_superuser_password_secret_id" {
  description = "The Secret Manager secret ID for the Django superuser password. If provided, this takes precedence. If empty, a new secret will be generated."
  type        = string
  default     = ""
}

variable "django_secret_key_secret_id" {
  description = "The Secret Manager secret ID for the Django SECRET_KEY. If provided, this takes precedence. If empty, a new secret will be generated."
  type        = string
  default     = ""
}

variable "extra_env_vars" {
  description = "A list of extra environment variables to set for the Cloud Run container. Each item can have a 'name' and either a 'value' or 'secret_id' and 'secret_version'."
  type = list(object({
    name           = string
    value          = optional(string)
    secret_id      = optional(string)
    secret_version = optional(string)
  }))
  default = []
}
