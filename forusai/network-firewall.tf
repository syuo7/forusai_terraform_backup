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

resource "google_compute_firewall" "service-port" {
  name    = "${var.app_name}-fw-allow-service-port"
  network = "${google_compute_network.vpc.name}"
  allow {
    protocol = "tcp"
    ports    = ["9000", "9001"]
  }
  target_tags = ["service-port"]
}
