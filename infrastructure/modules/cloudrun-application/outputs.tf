output "cloudrun_service_url" {
  description = "The URL of the deployed Cloud Run service."
  value       = google_cloud_run_v2_service.application_backend.uri
}

output "cloudrun_service_account_email" {
  description = "The email of the service account used by the Cloud Run service."
  value       = local.cloudrun_service_account.email
}

output "django_statics_bucket_name" {
  description = "The name of the Google Cloud Storage bucket for Django static files."
  value       = local.statics_bucket_name
}

output "django_uploads_bucket_name" {
  description = "The name of the Google Cloud Storage bucket for Django uploaded files."
  value       = local.uploads_bucket_name
}

output "django_superuser_password_secret_id" {
  description = "The Secret Manager secret ID for the Django superuser password, whether provided or newly generated."
  value       = local.effective_django_superuser_password_secret_id
}

output "django_secret_key_secret_id" {
  description = "The Secret Manager secret ID for the Django SECRET_KEY, whether provided or newly generated."
  value       = local.effective_django_secret_key_secret_id
}
