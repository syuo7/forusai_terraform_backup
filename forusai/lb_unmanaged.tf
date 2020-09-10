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
  port_name = "front-tcp"
  protocol  = "HTTP"
  health_checks = [
    google_compute_health_check.healthcheck_9000.self_link
  ]

  backend {
    group                 = google_compute_instance_group.ai-between-us-group.self_link
    balancing_mode        = "RATE"
    max_rate_per_instance = 100
  }
}

# define a group of virtual machines that will serve traffic for load balancing
resource "google_compute_backend_service" "backend" {
  name      = "${var.app_name}-backend"
  project   = var.app_project
  port_name = "backend-tcp"
  protocol  = "HTTP"
  health_checks = [
    google_compute_health_check.healthcheck_9001.self_link
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
    name = "front-tcp"
    port = "9000"
  }
  named_port {
    name = "backend-tcp"
    port = "9001"
  }
}

# Determine whether instances are responsive 9000 and able to do work
resource "google_compute_health_check" "healthcheck_9000" {
  name               = "${var.app_name}-healthcheck-9000"
  timeout_sec        = 1
  check_interval_sec = 1
  tcp_health_check {
    port = 9000
  }
}

# Determine whether instances are responsive 9001 and able to do work
resource "google_compute_health_check" "healthcheck_9001" {
  name               = "${var.app_name}-healthcheck-9001"
  timeout_sec        = 1
  check_interval_sec = 1
  tcp_health_check {
    port = 9001
  }
}

# Used to route requests to a backend service based on rules that you define for the host and path of an Incoming URL
resource "google_compute_url_map" "url_map" {
  name            = "${var.app_name}-load-balancer"
  project         = var.app_project
  default_service = google_compute_backend_service.backend_service.self_link

  host_rule {
    hosts        = ["ent.forus.ai"]
    path_matcher = "forusai-front"
  }

  host_rule {
    hosts        = ["backend.forus.ai"]
    path_matcher = "forusai-backend"
  }

  path_matcher {
    name            = "forusai-front"
    default_service = google_compute_backend_service.backend_service.self_link
  }
  
  path_matcher {
    name            = "forusai-backend"
    default_service = google_compute_backend_service.backend.self_link
  }
}

# Used to route requests to a backend service based on rules that you define for the host and path of an Incoming URL
resource "google_compute_url_map" "https_redirect" {
  name    = "${var.app_name}-https-redirect"
  project = var.app_project
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