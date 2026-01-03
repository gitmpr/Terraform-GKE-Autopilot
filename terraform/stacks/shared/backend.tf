terraform {
  backend "gcs" {
    bucket      = "tf-gcp-proj-main-tfstate"
    prefix      = "shared"
    credentials = "../../../terraform-gcp-sa-key.json"
  }
}
