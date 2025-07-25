terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.20.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~>4"
    }
  }
}

provider "google" {
  project = var.google_project_id
  region  = var.google_region
}

provider "google-beta" {
  project = var.google_project_id
  region  = var.google_region
}
