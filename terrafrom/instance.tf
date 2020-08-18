resource "google_compute_address" "ai-between-us-ip-address" {
  name = "ai-between-us-ip-address"
}

resource "google_compute_instance" "ai-between-us" {
  name = "ai-between-us"
  machine_type = "n1-standard-1"
  zone = "asia-northeast1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = "${google_compute_address.ai-between-us-ip-address.address}"
    }
  }

  metadata = {
    sshKeys = "forusai:${file("~/.ssh/ai-between-us.pub")}"
  }

    provisioner "remote-exec" {
    connection {
      host = self.network_interface[0].access_config[0].nat_ip
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
      #"git clone https://github.com/forus-ai/lyric-back.git"
    ]
    }
}