# GCP Service Account for workload identity
resource "google_service_account" "petclinic_app" {
  account_id   = "petclinic-app-${var.environment}"
  display_name = "PetClinic Application ${var.environment}"
  description  = "Service account for PetClinic app in ${var.environment}"
  project      = var.gcp_project_id
}

# Grant Cloud SQL Client role
resource "google_project_iam_member" "app_sql_client" {
  project = var.gcp_project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.petclinic_app.email}"
}

# Grant Secret Manager Secret Accessor role
resource "google_project_iam_member" "app_secret_accessor" {
  project = var.gcp_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.petclinic_app.email}"
}
