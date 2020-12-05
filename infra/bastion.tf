resource "google_compute_address" "bastion-address" {
  name         = "${var.PROJECT_ID}-bastion-ip"
  project      = var.PROJECT_ID
  region       = var.REGION
  network_tier = "PREMIUM"
  description  = "Public static IP for ${var.PROJECT_ID} bastion"
}


resource "google_compute_instance" "bastion" {
  name                      = "${var.PROJECT_ID}-bastion-vm"
  project                   = var.PROJECT_ID
  zone                      = var.ZONE
  machine_type              = "f1-micro"
  allow_stopping_for_update = true

  tags = [
    "bastion"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata_startup_script = file("./bastion-startup.sh")

  network_interface {
    subnetwork = google_compute_subnetwork.subnetwork.self_link
    access_config {
      nat_ip = google_compute_address.bastion-address.address
    }
  }

  metadata = {
    ssh-keys = "jarppe:${file("~/.ssh/id_rsa.pub")}"
  }
}


output "bastion-ip" {
  value = google_compute_address.bastion-address.address
}
