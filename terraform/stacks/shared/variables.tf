variable "gcp_project_id" {
  description = "GCP project ID for shared infrastructure"
  type        = string
  default     = "tf-gcp-proj-main"
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "europe-west1"
}

variable "artifact_registry_name" {
  description = "Artifact Registry repository name"
  type        = string
  default     = "petclinic-images"
}
