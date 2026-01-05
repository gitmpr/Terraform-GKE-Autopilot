provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  # Credentials provided via GOOGLE_APPLICATION_CREDENTIALS environment variable
  # For local development: export GOOGLE_APPLICATION_CREDENTIALS=path/to/key.json
  # For GitHub Actions: Uses OIDC authentication (no key file needed)
}
