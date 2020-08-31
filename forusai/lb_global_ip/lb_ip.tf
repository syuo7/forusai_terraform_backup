# Create a global IP Address
resource "google_compute_global_address" "forusai_ip" {
  name = "${var.app_name}-global-ip"
  ip_version = "IPV4"
  address_type = "EXTERNAL"
}

output "forusai_ip" {
  value = "${google_compute_global_address.forusai_ip.address}"
}