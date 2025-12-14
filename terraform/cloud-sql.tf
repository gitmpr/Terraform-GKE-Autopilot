# Cloud SQL PostgreSQL instance

resource "random_password" "db_password" {
  for_each = terraform.workspace != "main" ? toset(["this"]) : toset([])
  length   = 32
  special  = false
}

resource "google_sql_database_instance" "petclinic" {
  for_each         = terraform.workspace != "main" ? toset(["this"]) : toset([])
  name             = "petclinic-db-${var.environment_name}"
  database_version = "POSTGRES_15"
  region           = var.gcp_region
  project          = var.gcp_project_id

  settings {
    tier = "db-f1-micro"

    disk_type = "PD_SSD"
    disk_size = 10

    availability_type = var.sql_availability_type

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = false
      transaction_log_retention_days = 1
      backup_retention_settings {
        retained_backups = 7
      }
    }

    ip_configuration {
      ipv4_enabled = true
      ssl_mode     = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
    }
  }

  deletion_protection = false
}

resource "google_sql_database" "petclinic" {
  for_each = terraform.workspace != "main" ? toset(["this"]) : toset([])
  name     = "petclinic"
  instance = google_sql_database_instance.petclinic["this"].name
  project  = var.gcp_project_id
}

resource "google_sql_user" "petclinic" {
  for_each = terraform.workspace != "main" ? toset(["this"]) : toset([])
  name     = "petclinic"
  instance = google_sql_database_instance.petclinic["this"].name
  password = random_password.db_password["this"].result
  project  = var.gcp_project_id
}

# Store database password in Secret Manager
resource "google_secret_manager_secret" "db_password" {
  for_each  = terraform.workspace != "main" ? toset(["this"]) : toset([])
  secret_id = "petclinic-db-password-${var.environment_name}"
  project   = var.gcp_project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  for_each    = terraform.workspace != "main" ? toset(["this"]) : toset([])
  secret      = google_secret_manager_secret.db_password["this"].id
  secret_data = random_password.db_password["this"].result
}
