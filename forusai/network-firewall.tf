# allow http traffic
resource "google_compute_firewall" "allow-http" {
  name    = "${var.app_name}-fw-allow-http"
  network = "${google_compute_network.vpc.name}"
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  target_tags = ["http"]
}

# allow https traffic
resource "google_compute_firewall" "allow-https" {
  name    = "${var.app_name}-fw-allow-https"
  network = "${google_compute_network.vpc.name}"
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  target_tags = ["https"]
}

# allow ssh traffic
resource "google_compute_firewall" "allow-ssh" {
  name    = "${var.app_name}-fw-allow-ssh"
  network = "${google_compute_network.vpc.name}"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags = ["ssh"]
}

resource "google_compute_firewall" "front-port" {
  name    = "${var.app_name}-fw-allow-front-port"
  network = "${google_compute_network.vpc.name}"
  allow {
    protocol = "tcp"
    ports    = ["9000"]
  }
  target_tags = ["front-port"]
}


resource "google_compute_firewall" "backend-port" {
  name    = "${var.app_name}-fw-allow-backend-port"
  network = "${google_compute_network.vpc.name}"
  source_ranges = [
    /*
   "${google_compute_subnetwork.ai_between_us_subnet.ip_cidr_range}",
   "${google_compute_global_forwarding_rule.global_forwarding_rule_ssl.ip_address}",
   "115.178.87.144"
   */
  ]
  allow {
    protocol = "tcp"
    ports    = ["9001"]
  }
  target_tags = ["backend-port"]
}