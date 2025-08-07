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

variable "db_password_secret_id" {
  description = "The Secret Manager secret ID for the PostgreSQL database password. If provided, the module will reference this secret. If empty, a new secure password will be generated and stored in a new Secret Manager secret."
  type        = string
  default     = ""
}

variable "django_superuser_secret_id" {
  description = "The Secret Manager secret ID for the Django superuser password. If provided, the module will reference this secret. If empty, a new secure password will be generated and stored in a new Secret Manager secret."
  type        = string
  default     = ""
}

variable "django_secret_key_secret_id" {
  description = "The Secret Manager secret ID for the Django superuser password. If provided, the module will reference this secret. If empty, a new secure password will be generated and stored in a new Secret Manager secret."
  type        = string
  default     = ""
}

variable "ai_token_secret_id" {
  description = "The Secret Manager secret ID for the AI API token (e.g., OpenAI, Gemini). If provided, this takes precedence. If empty, 'ai_api_key' will be used."
  type        = string
  default     = ""
}

variable "ai_api_key" {
  description = "The direct value for the AI API token. Used if 'ai_token_secret_id' is empty."
  type        = string
  default     = "TODO:CHANGEME"
  sensitive   = true
}

variable "ai_api_key_env_var_name" {
  description = "The name of the environment variable to use for the AI API key in the Cloud Run container."
  type        = string
  default     = "GEMINI_API_KEY"
}

variable "github_google_cloud_build_installation_id" {
  type = string
}

variable "github_repository_uri" {
  type = string
}

variable "github_token_secret_value" {
  type      = string
  sensitive = true
  default   = "TODO:CHANGEME"
}
