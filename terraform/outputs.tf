output "service_url" {
  description = "URL of the Cloud Run service"
  value       = google_cloud_run_v2_service.petclinic.uri
}

output "service_name" {
  description = "Name of the Cloud Run service"
  value       = google_cloud_run_v2_service.petclinic.name
}

output "service_id" {
  description = "ID of the Cloud Run service"
  value       = google_cloud_run_v2_service.petclinic.id
}

output "db_instance_name" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.petclinic.name
}

output "db_connection_name" {
  description = "Cloud SQL instance connection name"
  value       = google_sql_database_instance.petclinic.connection_name
}

output "db_name" {
  description = "Database name"
  value       = google_sql_database.petclinic.name
}

output "db_user" {
  description = "Database user"
  value       = google_sql_user.petclinic.name
}

output "db_password_secret" {
  description = "Secret Manager secret name for database password"
  value       = google_secret_manager_secret.db_password.secret_id
}
