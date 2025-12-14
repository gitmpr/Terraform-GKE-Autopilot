variable "gcp_project_id" {
  description = "GCP project ID where resources will be created"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for resources"
  type        = string
  default     = "europe-west1"
}

variable "environment_name" {
  description = "Environment name (test/prod)"
  type        = string
}

variable "container_image" {
  description = "Full path to container image in Artifact Registry"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for Cloud Run"
  type        = string
}

variable "max_instances" {
  description = "Maximum number of Cloud Run instances"
  type        = number
  default     = 10
}

variable "min_instances" {
  description = "Minimum number of Cloud Run instances"
  type        = number
  default     = 0
}

variable "cpu_limit" {
  description = "CPU limit for Cloud Run service"
  type        = string
  default     = "1"
}

variable "memory_limit" {
  description = "Memory limit for Cloud Run service"
  type        = string
  default     = "512Mi"
}

variable "allow_unauthenticated" {
  description = "Allow unauthenticated access to Cloud Run service"
  type        = bool
  default     = true
}

variable "sql_availability_type" {
  description = "Availability type for Cloud SQL instance (ZONAL or REGIONAL)"
  type        = string
  default     = "ZONAL"
}
