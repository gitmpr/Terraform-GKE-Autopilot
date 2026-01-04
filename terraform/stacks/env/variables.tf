variable "gcp_project_id" {
  description = "GCP project ID for the environment"
  type        = string
}

variable "main_project_id" {
  description = "Main GCP project ID (where shared resources like Artifact Registry are located)"
  type        = string
  default     = "tf-gcp-proj-main"
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "europe-west1"
}

variable "environment" {
  description = "Environment name (test or prod)"
  type        = string
}

variable "container_image" {
  description = "Container image to deploy"
  type        = string
  default     = "europe-west1-docker.pkg.dev/tf-gcp-proj-main/petclinic-images/petclinic:latest"
}

variable "artifact_registry_name" {
  description = "Artifact Registry repository name"
  type        = string
  default     = "petclinic-images"
}

# GKE configuration
variable "gke_cluster_name" {
  description = "GKE cluster base name"
  type        = string
  default     = "gorillaclinic-k8s-gke"
}

# Cloud SQL configuration
variable "sql_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "sql_availability_type" {
  description = "Cloud SQL availability type (ZONAL or REGIONAL)"
  type        = string
  default     = "ZONAL"
}

variable "sql_backup_enabled" {
  description = "Enable Cloud SQL backups"
  type        = bool
  default     = true
}
