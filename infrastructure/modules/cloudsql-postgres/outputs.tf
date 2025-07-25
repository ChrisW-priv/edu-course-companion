output "instance_connection_name" {
  description = "The connection name of the Cloud SQL instance for connecting applications."
  value       = google_sql_database_instance.main_instance.connection_name
}

output "db_admin_user" {
  description = "The username for the PostgreSQL database admin user."
  value       = google_sql_user.admin_user.name
}

output "db_password_secret_id" {
  description = "The Secret Manager secret ID for the PostgreSQL database password."
  value       = local.effective_db_password_secret_id
}
