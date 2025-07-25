resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
  project                 = var.google_project_id
  provider                = google-beta
}

resource "google_compute_subnetwork" "vpc_subnetwork" {
  name          = var.subnetwork_name
  ip_cidr_range = var.subnetwork_ip_cidr_range
  region        = var.google_region
  network       = google_compute_network.vpc_network.self_link
  project       = var.google_project_id
  provider      = google-beta
}

resource "google_compute_subnetwork" "vpc_subnetwork_pga" {
  name                     = var.subnetwork_pga_name
  ip_cidr_range            = var.subnetwork_pga_ip_cidr_range
  region                   = var.google_region
  network                  = google_compute_network.vpc_network.self_link
  private_ip_google_access = true
  project                  = var.google_project_id
  provider                 = google-beta
}

resource "google_compute_global_address" "private_ip_alloc_range" {
  name          = "google-managed-services-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.self_link
  project       = var.google_project_id
  provider      = google-beta
}

resource "google_service_networking_connection" "vpc_connection" {
  network                 = google_compute_network.vpc_network.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc_range.name]
  depends_on              = [google_compute_global_address.private_ip_alloc_range]
  provider                = google-beta
}
