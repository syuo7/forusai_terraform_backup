provider "google" {
  version = "~> 2.5"
  credentials = "${file("ai-between-us-80d52d0fe72f.json")}"
  project = "ai-between-us"
  region = "asia-northeast1"
}