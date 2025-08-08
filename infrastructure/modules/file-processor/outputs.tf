output "cloud_run_job_name" {
  description = "Name of the Cloud Run Service"
  value       = google_cloud_run_v2_service.extractor.name
}
