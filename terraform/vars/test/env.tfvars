gcp_project_id        = "tf-gcp-proj-test"
gcp_region            = "europe-west1"
environment_name      = "test"
container_image       = "europe-west1-docker.pkg.dev/tf-gcp-proj-main/petclinic-images/petclinic:latest"
service_account_email = "cloudrun-petclinic-sa@tf-gcp-proj-test.iam.gserviceaccount.com"

max_instances         = 10
min_instances         = 0
cpu_limit             = "1"
memory_limit          = "512Mi"
allow_unauthenticated = true
