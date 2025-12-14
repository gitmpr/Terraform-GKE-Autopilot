# Cloud Run Service Account
# This is the identity that the Cloud Run service runs as (workload identity)
# It needs permissions to access Cloud SQL and Secret Manager

resource "google_service_account" "cloudrun_petclinic" {
  for_each = terraform.workspace != "main" ? toset(["this"]) : toset([])

  account_id   = "cloudrun-petclinic-sa"
  display_name = "Cloud Run PetClinic Service Account"
  description  = "Service account for Cloud Run PetClinic application in ${var.environment_name} environment"
  project      = var.gcp_project_id
}

# Grant Cloud SQL Client role to access Cloud SQL instances
resource "google_project_iam_member" "cloudrun_cloudsql_client" {
  for_each = terraform.workspace != "main" ? toset(["this"]) : toset([])

  project = var.gcp_project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloudrun_petclinic["this"].email}"
}

# Grant Secret Manager Secret Accessor role to read database password
resource "google_project_iam_member" "cloudrun_secret_accessor" {
  for_each = terraform.workspace != "main" ? toset(["this"]) : toset([])

  project = var.gcp_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloudrun_petclinic["this"].email}"
}
