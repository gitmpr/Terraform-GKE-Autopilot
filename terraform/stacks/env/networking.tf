# VPC Network for GKE and Cloud SQL
resource "google_compute_network" "vpc" {
  name                    = "petclinic-vpc-${var.environment}"
  auto_create_subnetworks = false
  project                 = var.gcp_project_id
}

# Subnet for GKE nodes
resource "google_compute_subnetwork" "gke" {
  name          = "gke-subnet-${var.environment}"
  ip_cidr_range = "10.0.0.0/20"  # 4096 IPs for nodes
  region        = var.gcp_region
  network       = google_compute_network.vpc.id
  project       = var.gcp_project_id

  # Secondary ranges for pods and services
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.4.0.0/14"  # ~262k IPs for pods
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.8.0.0/20"  # 4096 IPs for services
  }

  private_ip_google_access = true
}

# Cloud Router for Cloud NAT (required for private GKE cluster)
resource "google_compute_router" "router" {
  name    = "nat-router-${var.environment}"
  region  = var.gcp_region
  network = google_compute_network.vpc.id
  project = var.gcp_project_id
}

# Cloud NAT for outbound internet access from private cluster
resource "google_compute_router_nat" "nat" {
  name                               = "nat-config-${var.environment}"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = var.gcp_project_id

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Reserve IP range for Google services (Cloud SQL)
resource "google_compute_global_address" "private_ip_range" {
  name          = "private-ip-range-${var.environment}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
  project       = var.gcp_project_id
}

# Create private VPC connection for Cloud SQL
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}
