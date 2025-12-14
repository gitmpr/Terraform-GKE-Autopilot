# Shared infrastructure in the main project
# This is created once and used by all environments (test/prod)

# Artifact Registry for container images (shared across environments)
resource "google_artifact_registry_repository" "petclinic_images" {
  provider = google

  project       = "tf-gcp-proj-main"
  location      = "europe-west1"
  repository_id = "petclinic-images"
  description   = "PetClinic container images"
  format        = "DOCKER"

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = false  # Set to true after initial setup
  }
}
