# GCP Service Account for workload identity
resource "google_service_account" "petclinic_app" {
  account_id   = "petclinic-app-${var.environment}"
  display_name = "PetClinic Application ${var.environment}"
  description  = "Service account for PetClinic app in ${var.environment}"
  project      = var.gcp_project_id
}

# Grant Cloud SQL Client role scoped to specific instance using IAM Condition
resource "google_project_iam_member" "app_sql_client" {
  project = var.gcp_project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.petclinic_app.email}"

  condition {
    title       = "Cloud SQL instance access for ${var.environment}"
    description = "Restricts cloudsql.client role to specific instance"
    expression  = "resource.name == 'projects/${var.gcp_project_id}/instances/${google_sql_database_instance.petclinic.name}' && resource.service == 'sqladmin.googleapis.com'"
  }
}

# Grant Secret Manager Secret Accessor role at secret scope (not project-wide)
resource "google_secret_manager_secret_iam_member" "app_secret_accessor" {
  project   = var.gcp_project_id
  secret_id = google_secret_manager_secret.db_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.petclinic_app.email}"
}

# Grant Artifact Registry Reader role at repository scope (not project-wide)
resource "google_artifact_registry_repository_iam_member" "app_artifact_reader" {
  project    = var.main_project_id
  location   = var.gcp_region
  repository = var.artifact_registry_name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.petclinic_app.email}"
}

# Workload Identity binding - allows Kubernetes SA to impersonate GCP SA
resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = google_service_account.petclinic_app.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project_id}.svc.id.goog[petclinic-${var.environment}/petclinic]"
}
