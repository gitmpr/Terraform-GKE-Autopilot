# Artifact Registry for container images
# Shared across all environments (test, prod)
resource "google_artifact_registry_repository" "petclinic_images" {
  location      = var.gcp_region
  repository_id = var.artifact_registry_name
  description   = "PetClinic container images for all environments"
  format        = "DOCKER"
  project       = var.gcp_project_id
}
