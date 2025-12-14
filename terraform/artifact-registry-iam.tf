# Get the current project's number (whichever workspace we're in, e.g., 'test' or 'prod')
data "google_project" "current" {
  for_each   = terraform.workspace != "main" ? toset(["this"]) : toset([])
  project_id = var.gcp_project_id
}

# Grant the Cloud Run Service Agent permission to pull images from Artifact Registry
# The Cloud Run Service Agent is automatically created when Cloud Run is enabled
resource "google_artifact_registry_repository_iam_member" "cloud_run_agent" {
  for_each = terraform.workspace != "main" ? toset(["this"]) : toset([])

  project    = "tf-gcp-proj-main"
  location   = "europe-west1"
  repository = "petclinic-images"
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:service-${data.google_project.current["this"].number}@serverless-robot-prod.iam.gserviceaccount.com"
}
