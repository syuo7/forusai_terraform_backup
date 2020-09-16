variable "private_key_path" {
  default = "~/.ssh/ai-between-us"
}

# GCP Prject Name
variable "app_project" {
  type        = string
  default     = "ai-between-us"
  description = "GCP Project Name"
}

variable "gcp_zone" {
  type        = "string"
  default     = "asia-northeast1-a"
  description = "GCP zone"
}

variable "gcp_region" {
  type        = "string"
  default     = "asia-northeast1"
  description = "GCP region"
}

variable "app_name" {
  type        = "string"
  default     = "forusai"
  description = "app name"
}

variable "private_subnet_cidr" {
  type        = "string"
  default     = "10.10.0.0/24"
  description = "private subnet cidr of forusai"
}

variable "machine_type" {
  type = "string"
  description = "gcp instance price type"
}