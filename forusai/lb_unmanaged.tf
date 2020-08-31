# LB with unmanaged instance group 

/*
module "global_ip" {
  source = "./lb_global_ip"
}
*/

data "terraform_remote_state" "ip" {
  backend = "gcs"
  config = {
    bucket = "ai-between-us-bucket"
    prefix = "prod/ip"
  }
}

# used to forward traffic to the correct load balancer for HTTP loadbalancing
resource "google_compute_global_forwarding_rule" "global_forwarding_rule" {
  name    = "${var.app_name}-global-forwarding-rule"
  project = var.app_project
  #ip_address = google_compute_global_address.forusai_ip.address
  ip_address = data.terraform_remote_state.ip.outputs.forusai_ip
  target     = google_compute_target_http_proxy.target_http_proxy.self_link
  port_range = 80
}


# used to forward traffic to the correct load balancer for HTTP loadbalancing (SSL)
resource "google_compute_global_forwarding_rule" "global_forwarding_rule_ssl" {
  name    = "${var.app_name}-global-forwarding-rule-ssl"
  project = var.app_project
  #ip_address = google_compute_global_address.forusai_ip.address
  ip_address = data.terraform_remote_state.ip.outputs.forusai_ip
  target     = google_compute_target_https_proxy.target_https_proxy.self_link
  port_range = 443
}


# Used by one or more global forwarding rule to route incoming HTTP request to a URL map
resource "google_compute_target_http_proxy" "target_http_proxy" {
  name    = "${var.app_name}-proxy"
  project = var.app_project
  url_map = google_compute_url_map.https_redirect.self_link
}

# Used by one or more global forwarding rule to route incoming HTTP request to a URL map(SSL)
resource "google_compute_target_https_proxy" "target_https_proxy" {
  name             = "${var.app_name}-proxy-ssl"
  ssl_certificates = [google_compute_ssl_certificate.forusai.id]
  project          = var.app_project
  url_map          = google_compute_url_map.url_map.self_link
}

# define a group of virtual machines that will serve traffic for load balancing
resource "google_compute_backend_service" "backend_service" {
  name      = "${var.app_name}-backend-service"
  project   = var.app_project
  port_name = "tcp"
  protocol  = "HTTP"
  health_checks = [
    google_compute_health_check.healthcheck.self_link
  ]

  backend {
    group                 = google_compute_instance_group.ai-between-us-group.self_link
    balancing_mode        = "RATE"
    max_rate_per_instance = 100
  }
}

# Create a group of dissimilar virtual machine instances
resource "google_compute_instance_group" "ai-between-us-group" {
  name        = "${var.app_name}-vm-group"
  description = "ai-between-us instance group"
  zone        = var.gcp_zone
  instances = [
    google_compute_instance.ai-between-us.self_link
  ]
  named_port {
    name = "tcp"
    port = "9000"
  }
}

# Determine whether instances are responsive and able to do work
resource "google_compute_health_check" "healthcheck" {
  name               = "${var.app_name}-healthcheck"
  timeout_sec        = 1
  check_interval_sec = 1
  tcp_health_check {
    port = 9000
  }
}

# Used to route requests to a backend service based on rules that you define for the host and path of an Incoming URL
resource "google_compute_url_map" "url_map" {
  name            = "${var.app_name}-load-balancer"
  project         = var.app_project
  default_service = google_compute_backend_service.backend_service.self_link
  
}

# Used to route requests to a backend service based on rules that you define for the host and path of an Incoming URL
resource "google_compute_url_map" "https_redirect" {
  name            = "${var.app_name}-https-redirect"
  project         = var.app_project
 # default_service = google_compute_backend_service.backend_service.self_link

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

# Show external ip address of load balancer 
output "load-balancer-ip-address" {
  value = google_compute_global_forwarding_rule.global_forwarding_rule_ssl.ip_address
}

/*
resource "google_compute_managed_ssl_certificate" "forusai" {
  provider = google-beta

  name = "ssl-for-forusai"

  managed {
    domains = ["forus.ai."]
  }
}
*/

resource "google_compute_ssl_certificate" "forusai" {
  # The name will contain 8 random hex digits,
  # e.g. "my-certificate-48ab27cd2a"
  name_prefix = "forusai-"
  private_key = file("./privkey1.pem")
  certificate = file("./fullchain1.pem")

  lifecycle {
    create_before_destroy = true
  }
}

/*
resource "google_dns_managed_zone" "zone" {
  provider = google-beta

  name     = "dnszone"
  dns_name = "forus.ai."
}

resource "google_dns_record_set" "set" {
  provider = google-beta

  name         = "ent.forus.ai."
  type         = "A"
  ttl          = 3600
  managed_zone = google_dns_managed_zone.zone.name
  rrdatas      = [google_compute_global_forwarding_rule.global_forwarding_rule_ssl.ip_address]
}
*/