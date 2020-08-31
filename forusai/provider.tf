provider "google" {
  version     = "~> 3.20"
  credentials = "${file("./ai-between-us-80d52d0fe72f.json")}"
  project     = var.app_project
  region      = var.gcp_region
}

provider "google-beta" {
  # version = "~> 2.5"
  credentials = "${file("./ai-between-us-80d52d0fe72f.json")}"
  project     = var.app_project
  region      = var.gcp_region
}