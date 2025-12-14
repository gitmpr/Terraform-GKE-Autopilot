# Shared infrastructure in the main project
# This is created once and used by all environments (test/prod)

# The Artifact Registry repository is a shared resource that should only be provisioned
# in the 'main' Terraform workspace. The 'for_each' meta-argument combined with
# 'terraform.workspace == "main"' ensures this resource is only created when
# the active workspace is 'main'. Other workspaces will use a remote state
# data source to reference this repository.
resource "google_artifact_registry_repository" "petclinic_images" {
  for_each = terraform.workspace == "main" ? toset(["this"]) : toset([])

  project       = "tf-gcp-proj-main"
  location      = "europe-west1"
  repository_id = "petclinic-images"
  description   = "PetClinic container images"
  format        = "DOCKER"

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = false # Set to true after initial setup
  }
}

output "artifact_registry_repository_name" {
  description = "The name of the shared Artifact Registry repository."
  value       = terraform.workspace == "main" ? one(values(google_artifact_registry_repository.petclinic_images)).name : null
}
