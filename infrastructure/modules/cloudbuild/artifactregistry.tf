locals {
  # Registry creation flag
  is_creating_registry = var.artifact_registry_url == ""

  # Registry name
  registry_id = "main-registry"

  # Registry URL
  artifact_registry_url = local.is_creating_registry ? "${var.google_region}-docker.pkg.dev/${var.google_project_id}/${local.registry_id}" : var.artifact_registry_url
}

# Create a new Artifact Registry if none provided
resource "google_artifact_registry_repository" "docker" {
  count         = local.is_creating_registry ? 1 : 0
  repository_id = local.registry_id
  project       = var.google_project_id
  location      = var.google_region
  format        = "DOCKER"
  description   = "Primary Docker Artifact Registry for the Application"
}
