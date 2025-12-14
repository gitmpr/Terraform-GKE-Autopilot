gcp_project_id        = "tf-gcp-proj-main"
gcp_region            = "europe-west1"
environment_name      = "main"
container_image       = "dummy-image-for-validation"
service_account_email = "dummy-sa@dummy.iam.gserviceaccount.com"
sql_availability_type = "ZONAL" # This value is not used in the main workspace but needs to be present

# The following values are also not used by any resources created
# in the 'main' workspace, but are provided to prevent prompts.
max_instances         = 1
min_instances         = 0
cpu_limit             = "1"
memory_limit          = "512Mi"
allow_unauthenticated = false
