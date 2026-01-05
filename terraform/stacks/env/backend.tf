terraform {
  backend "gcs" {
    bucket = "tf-gcp-proj-main-tfstate"
    prefix = "env"
    # Credentials provided via GOOGLE_APPLICATION_CREDENTIALS environment variable
    # For local development: export GOOGLE_APPLICATION_CREDENTIALS=path/to/key.json
    # For GitHub Actions: Uses OIDC authentication (no key file needed)
  }
}
