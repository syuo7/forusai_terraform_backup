# IP address of instance
/*
output "ai-between-us-public-ip" {
  value = google_compute_address.ai-between-us-ip-address.address
}
*/

/*
output "ai-between-us-private-ip" {
  value = google_compute_address.ai-between-us.network_interface.0.network_ip
}
*/


output "nat_ip_address" {
  value = google_compute_address.nat-ip.address
}

# Show external ip address of load balancer 
output "load-balancer-ip-address" {
  value = google_compute_global_forwarding_rule.global_forwarding_rule_ssl.ip_address
}