variable "google_project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "google_region" {
  description = "The GCP region for the Cloud SQL instance."
  type        = string
}

variable "instance_name" {
  description = "The name of the Cloud SQL instance."
  type        = string
}

variable "instance_tier" {
  description = "The machine type for the Cloud SQL instance (e.g., db-f1-micro)."
  type        = string
  default     = "db-f1-micro"
}

variable "db_user" {
  description = "The username for the PostgreSQL database admin user."
  type        = string
  default     = "postgres"
}

variable "database_name" {
  description = "The name of the database to create within the instance."
  type        = string
  default     = "postgres"
}

variable "db_password_secret_id" {
  description = "The Secret Manager secret ID for the PostgreSQL database password. If provided, the module will reference this secret. If empty, a new secure password will be generated and stored in a new Secret Manager secret."
  type        = string
  default     = ""
}

variable "vpc_network" {
  description = "The VPC network to which the Cloud SQL instance is connected. Used for private IP."
  type        = string
}
