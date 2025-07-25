resource "google_project_service" "vertex_ai_services" {
  for_each = toset([
    "aiplatform.googleapis.com",
  ])

  project            = var.google_project_id
  service            = each.value
  disable_on_destroy = false
}
