locals {
  is_main_workspace = terraform.workspace == "main"

  # Hardcode the artifact registry name for now to bypass remote state reading issues.
  # This repository is always named "petclinic-images".
  artifact_registry_repository_name = "petclinic-images"

  # Determine the artifact registry location. For simplicity, it's hardcoded here,
  # but could also be an output from the 'main' state.
  artifact_registry_location = "europe-west1"

  # Determine the artifact registry project.
  artifact_registry_project_id = "tf-gcp-proj-main"
}
