# This data source is used in the 'test' and 'prod' workspaces to
# access the outputs (like the shared artifact registry name) from the
# 'main' workspace's state file.

data "terraform_remote_state" "main" {
  count = terraform.workspace == "main" ? 0 : 1

  backend = "gcs"
  config = {
    bucket = "tf-gcp-proj-main-tfstate"
    prefix = "terraform/state/main"
  }
}
