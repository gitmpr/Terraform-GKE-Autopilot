output "artifact_registry_repository" {
  description = "Artifact Registry repository name"
  value       = google_artifact_registry_repository.petclinic_images.name
}

output "artifact_registry_location" {
  description = "Artifact Registry location"
  value       = google_artifact_registry_repository.petclinic_images.location
}

output "container_image_base" {
  description = "Base path for container images"
  value       = "${google_artifact_registry_repository.petclinic_images.location}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.petclinic_images.repository_id}"
}
