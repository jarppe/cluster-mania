resource "google_compute_network" "vpc" {
  name                    = "${var.PROJECT_ID}-vpc"
  project                 = var.PROJECT_ID
  auto_create_subnetworks = false
}


resource "google_compute_subnetwork" "subnetwork" {
  name          = "${var.PROJECT_ID}-sn"
  project       = var.PROJECT_ID
  network       = google_compute_network.vpc.self_link
  region        = var.REGION
  ip_cidr_range = "10.0.1.0/24"
}


resource "google_compute_firewall" "firewall" {
  name        = "${var.PROJECT_ID}-fw"
  network     = google_compute_network.vpc.self_link
  project     = var.PROJECT_ID
  direction   = "INGRESS"
  priority    = 500
  description = "Allow SSH"

  source_ranges = [
    # Hemma hus Jarppe
    "83.245.216.46/32",
    # Meto Tre
    "212.50.128.0/24"]

  target_tags = [
    "bastion"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = [
      "22"]
  }
}

resource "google_compute_firewall" "firewall-allow-rdp" {
  name        = "${var.PROJECT_ID}-fw-allow-rdp"
  network     = google_compute_network.vpc.self_link
  project     = var.PROJECT_ID
  direction   = "INGRESS"
  priority    = 500
  description = "Allow IAP RDP"

  source_ranges = [
    "35.235.240.0/20"]

  allow {
    protocol = "tcp"
    ports    = [
      "3389"]
  }
}
