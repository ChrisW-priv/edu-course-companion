output "input_bucket_name" {
  description = "GCS bucket used for inputs"
  value       = local.input_bucket_name
}

output "output_bucket_name" {
  description = "GCS bucket used for outputs"
  value       = local.output_bucket_name
}

output "cloud_run_job_name" {
  description = "Name of the Cloud Run Job"
  value       = google_cloud_run_v2_job.extractor.name
}
