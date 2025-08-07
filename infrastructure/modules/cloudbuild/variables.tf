variable "google_project_id" {
  type = string
}

variable "google_region" {
  type = string
}

variable "google_project_number" {
  type = string
}

variable "connection_name" {
  type    = string
  default = ""
}

variable "artifact_registry_url" {
  type    = string
  default = ""
}

variable "cloud_build_service_account_email" {
  type    = string
  default = ""
}

variable "github_token_secret_id" {
  type    = string
  default = ""
}

variable "github_token_secret_value" {
  type      = string
  default   = "CHANGE_ME!"
  sensitive = true
}

variable "github_google_cloud_build_installation_id" {
  type = string
}

variable "github_repository_uri" {
  type = string
}
