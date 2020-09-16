# Create the ai-between-us VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.app_name}-vpc"
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
}

# Cretea private subnet
resource "google_compute_subnetwork" "ai_between_us_subnet" {
  provider = "google"
  # purpose = "PRIVATE"
  name          = "${var.app_name}-private-subnet"
  ip_cidr_range = var.private_subnet_cidr
  network       = google_compute_network.vpc.id
  region        = var.gcp_region
  depends_on = [ google_compute_network.vpc ]
}
/* Specific private ip 

resource "google_compute_address" "private_ai_between_us" {
  name = "internal-ai-between-us"
  subnetwork = google_compute_subnetwork.ai_between_us_subnet.id
  address_type = "INTERNAL"
  address = "10.10.0.10"
}
*/

# Create a public ip for nat subnet
resource "google_compute_address" "nat-ip" {
  name    = "${var.app_name}-nap-ip"
  project = var.app_project
  region  = var.gcp_region
}

# Create a nat to allow private instances connect to internet
resource "google_compute_router" "nat-router" {
  name    = "${var.app_name}-nat-router"
  network = "${google_compute_network.vpc.id}"
  depends_on = [ google_compute_network.vpc ]
}

resource "google_compute_router_nat" "nat-gateway" {
  name                               = "${var.app_name}-nat-gateway"
  router                             = google_compute_router.nat-router.name
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat-ip.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  depends_on                         = [google_compute_address.nat-ip]
}

output "nat_ip_address1" {
  value = google_compute_address.nat-ip.address
}
