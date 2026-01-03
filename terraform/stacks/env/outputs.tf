output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.autopilot.name
}

output "gke_cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.autopilot.endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = google_container_cluster.autopilot.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "db_instance_name" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.petclinic.name
}

output "db_private_ip" {
  description = "Cloud SQL private IP address"
  value       = google_sql_database_instance.petclinic.private_ip_address
}

output "db_connection_name" {
  description = "Cloud SQL connection name"
  value       = google_sql_database_instance.petclinic.connection_name
}

output "vpc_network" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "workload_identity_sa" {
  description = "Workload identity service account email"
  value       = google_service_account.petclinic_app.email
}
