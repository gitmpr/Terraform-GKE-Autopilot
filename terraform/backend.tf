terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "gcs" {
    bucket      = "tf-gcp-proj-main-tfstate"
    prefix      = "terraform/state"
    credentials = "../terraform-gcp-sa-key.json"
  }
}

provider "google" {
  project     = var.gcp_project_id
  region      = var.gcp_region
  credentials = "../terraform-gcp-sa-key.json"
}
