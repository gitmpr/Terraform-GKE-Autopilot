terraform {
  backend "gcs" {
    bucket      = "tf-gcp-proj-main-tfstate"
    prefix      = "env"
    credentials = "../../../terraform-gcp-sa-key.json"
  }
}
