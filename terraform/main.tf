resource "google_cloud_run_v2_service" "petclinic" {
  name     = "petclinic-${var.environment_name}"
  location = var.gcp_region
  project  = var.gcp_project_id

  template {
    service_account = var.service_account_email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    # Cloud SQL connection
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.petclinic.connection_name]
      }
    }

    containers {
      image = var.container_image

      resources {
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
      }

      ports {
        container_port = 8080
      }

      # Mount Cloud SQL volume
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      # PostgreSQL database configuration
      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = "postgres"
      }

      env {
        name  = "SPRING_DATASOURCE_URL"
        value = "jdbc:postgresql:///${google_sql_database.petclinic.name}?cloudSqlInstance=${google_sql_database_instance.petclinic.connection_name}&socketFactory=com.google.cloud.sql.postgres.SocketFactory"
      }

      env {
        name  = "SPRING_DATASOURCE_USERNAME"
        value = google_sql_user.petclinic.name
      }

      env {
        name = "SPRING_DATASOURCE_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

# Allow unauthenticated access (for MVP)
resource "google_cloud_run_v2_service_iam_member" "noauth" {
  count = var.allow_unauthenticated ? 1 : 0

  project  = google_cloud_run_v2_service.petclinic.project
  location = google_cloud_run_v2_service.petclinic.location
  name     = google_cloud_run_v2_service.petclinic.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
