# Create a public ip of instance for remote-exec
resource "google_compute_address" "ai-between-us-ip-address" {
  name = "ai-between-us-ip-address"
}


resource "google_compute_instance" "ai-between-us" {
  depends_on   = [google_compute_router_nat.nat-gateway]
  name         = var.app_name
  machine_type = "n1-standard-1"
  zone         = var.gcp_zone
  tags         = ["ssh", "http", "https", "service-port"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.ai_between_us_subnet.name
    access_config {
      nat_ip = "${google_compute_address.ai-between-us-ip-address.address}"
    }
  }

  metadata = {
    sshKeys = "forusai:${file("~/.ssh/ai-between-us.pub")}"
  }

  provisioner "file" {
    source      = ".env"
    destination = "$HOME/.env"
    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = "forusai"
      private_key = "${file("${var.private_key_path}")}"
      agent       = false
    }
  }

  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "$HOME/docker-compose.yml"
    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = "forusai"
      private_key = "${file("${var.private_key_path}")}"
      agent       = false
    }
  }

  provisioner "remote-exec" {
    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = "forusai"
      private_key = "${file("${var.private_key_path}")}"
      agent       = false
    }

    inline = [
      "sudo curl -sSL https://get.docker.com/ | sh",
      "sudo usermod -aG docker `echo $USER`",
      "sudo apt-get -y update",
      "sudo apt-get install -y git",
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo cd $HOME",
      "sudo docker-compose up -d"
      #"git clone https://github.com/forus-ai/lyric-back.git"
    ]
  }

}