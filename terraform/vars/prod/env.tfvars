gcp_project_id        = "tf-gcp-proj-prod"
gcp_region            = "europe-west1"
environment_name      = "prod"
container_image       = "europe-west1-docker.pkg.dev/tf-gcp-proj-main/petclinic-images/petclinic:latest"
service_account_email = "cloudrun-petclinic-sa@tf-gcp-proj-prod.iam.gserviceaccount.com"

max_instances         = 100
min_instances         = 1
cpu_limit             = "2"
memory_limit          = "1Gi"
allow_unauthenticated = true
