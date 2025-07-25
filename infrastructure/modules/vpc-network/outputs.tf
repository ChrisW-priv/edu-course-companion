output "vpc_network_self_link" {
  description = "The self_link of the VPC network."
  value       = google_compute_network.vpc_network.self_link
}

output "vpc_subnetwork_self_link" {
  description = "The self_link of the primary subnetwork."
  value       = google_compute_subnetwork.vpc_subnetwork.self_link
}

output "vpc_subnetwork_pga_self_link" {
  description = "The self_link of the subnetwork with Private Google Access enabled."
  value       = google_compute_subnetwork.vpc_subnetwork_pga.self_link
}
