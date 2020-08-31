resource "google_storage_bucket" "terraform_state" {
  name = "ai-between-us-bucket"
  #storage_class = "REGIONAL"
  location = "asia-northeast1"
  force_destroy = "true"

  versioning {
    enabled = true
  }

}
/*
terraform {
  backend "gcs" {
    bucket = "ai-between-us-bucket"
    prefix = "prod/terraform.tfstate"
  }
}
*/


