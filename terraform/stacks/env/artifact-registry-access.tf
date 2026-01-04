# Grant GKE cluster's default compute service account access to pull images
# from Artifact Registry in the main project

# Get the default compute service account for this project
data "google_compute_default_service_account" "default" {
  project = var.gcp_project_id
}

# Grant Artifact Registry Reader role to allow image pulls
resource "google_project_iam_member" "artifact_registry_reader" {
  project = var.main_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}
