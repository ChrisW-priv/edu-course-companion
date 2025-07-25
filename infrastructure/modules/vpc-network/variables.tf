variable "google_project_id" {
  description = "The GCP project ID where the VPC network will be created."
  type        = string
}

variable "google_region" {
  description = "The GCP region for the subnetwork."
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network."
  type        = string
  default     = "main-vpc-network"
}

variable "subnetwork_name" {
  description = "The name of the subnetwork within the VPC."
  type        = string
  default     = "main-subnet"
}

variable "subnetwork_ip_cidr_range" {
  description = "The IP CIDR range for the subnetwork (e.g., \"10.0.0.0/20\")."
  type        = string
  default     = "10.0.0.0/20"
}

variable "subnetwork_pga_name" {
  description = "The name of the subnetwork with Private Google Access enabled."
  type        = string
  default     = "private-google-access-subnet"
}

variable "subnetwork_pga_ip_cidr_range" {
  description = "The IP CIDR range for the subnetwork with Private Google Access enabled."
  type        = string
  default     = "10.0.32.0/20"
}
