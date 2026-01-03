# Generate random password for database
resource "random_password" "db_password" {
  length  = 32
  special = false
}

# Cloud SQL PostgreSQL instance with private IP only
resource "google_sql_database_instance" "petclinic" {
  name             = "petclinic-db-${var.environment}"
  database_version = "POSTGRES_15"
  region           = var.gcp_region
  project          = var.gcp_project_id

  # Prevent accidental deletion
  deletion_protection = false  # Set to true for production

  # Wait for private VPC connection to be established
  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = var.sql_tier
    availability_type = var.sql_availability_type
    disk_size         = 10
    disk_type         = "PD_SSD"

    # Private IP configuration - no public IP
    ip_configuration {
      ipv4_enabled                                  = false  # No public IP
      private_network                               = google_compute_network.vpc.id
      enable_private_path_for_google_cloud_services = true
    }

    # Backup configuration
    backup_configuration {
      enabled                        = var.sql_backup_enabled
      start_time                     = "03:00"
      point_in_time_recovery_enabled = var.sql_availability_type == "REGIONAL"
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }

    # Maintenance window
    maintenance_window {
      day          = 7  # Sunday
      hour         = 3
      update_track = "stable"
    }
  }
}

# Database
resource "google_sql_database" "petclinic" {
  name     = "petclinic"
  instance = google_sql_database_instance.petclinic.name
  project  = var.gcp_project_id
}

# Database user
resource "google_sql_user" "petclinic" {
  name     = "petclinic"
  instance = google_sql_database_instance.petclinic.name
  password = random_password.db_password.result
  project  = var.gcp_project_id
}

# Store password in Secret Manager
resource "google_secret_manager_secret" "db_password" {
  secret_id = "petclinic-db-password-${var.environment}"
  project   = var.gcp_project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}
