# Grant Cloud Run Service Agent permission to pull images from Artifact Registry
# This is needed because the registry is in tf-gcp-proj-main but Cloud Run
# services are deployed in separate test/prod projects

# Get the current project's number (whichever workspace we're in)
data "google_project" "current" {
  project_id = var.gcp_project_id
}

# Grant the Cloud Run Service Agent from the current project access to pull images
resource "google_artifact_registry_repository_iam_member" "cloud_run_agent" {
  project    = "tf-gcp-proj-main"
  location   = "europe-west1"
  repository = "petclinic-images"
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:service-${data.google_project.current.number}@serverless-robot-prod.iam.gserviceaccount.com"
}
