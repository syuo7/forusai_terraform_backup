resource "google_storage_bucket" "terraform_state" {
  name = "ai-between-us-state"
  location = "asia-northeast1"

  versioning {
    enabled = "true"
  }
}