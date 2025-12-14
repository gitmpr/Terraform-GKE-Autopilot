output "service_url" {
  description = "URL of the Cloud Run service"
  value       = terraform.workspace != "main" ? google_cloud_run_v2_service.petclinic["this"].uri : null
}

output "service_name" {
  description = "Name of the Cloud Run service"
  value       = terraform.workspace != "main" ? google_cloud_run_v2_service.petclinic["this"].name : null
}

output "service_id" {
  description = "ID of the Cloud Run service"
  value       = terraform.workspace != "main" ? google_cloud_run_v2_service.petclinic["this"].id : null
}

output "db_instance_name" {
  description = "Cloud SQL instance name"
  value       = terraform.workspace != "main" ? google_sql_database_instance.petclinic["this"].name : null
}

output "db_connection_name" {
  description = "Cloud SQL instance connection name"
  value       = terraform.workspace != "main" ? google_sql_database_instance.petclinic["this"].connection_name : null
}

output "db_name" {
  description = "Database name"
  value       = terraform.workspace != "main" ? google_sql_database.petclinic["this"].name : null
}

output "db_user" {
  description = "Database user"
  value       = terraform.workspace != "main" ? google_sql_user.petclinic["this"].name : null
}

output "db_password_secret" {
  description = "Secret Manager secret name for database password"
  value       = terraform.workspace != "main" ? google_secret_manager_secret.db_password["this"].secret_id : null
}
