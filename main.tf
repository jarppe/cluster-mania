provider "google" {
  version     = "3.49.0"
  project     = var.PROJECT_ID
  region      = var.REGION
  credentials = file(var.CREDS)
}


terraform {
  required_version = ">=0.13.4"
  backend "gcs" {
    prefix = "terraform/state"
  }
}


resource "random_id" "instance_id" {
  byte_length = 8
}


//
// ====================================================================
// Network:
// ====================================================================
//


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
    "83.245.216.0/24",
    # Meto Tre
    "212.50.128.0/24"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = [
      "22"]
  }
}


resource "google_compute_address" "bastion-address" {
  name         = "${var.PROJECT_ID}-bastion-ip"
  project      = var.PROJECT_ID
  region       = var.REGION
  network_tier = "PREMIUM"
  description  = "Public static IP for ${var.PROJECT_ID} bastion"
}


output "bastion-ip" {
  value = google_compute_address.bastion-address.address
}


//
// ====================================================================
// Bastion:
// ====================================================================
//


resource "google_compute_instance" "bastion" {
  name                      = "${var.PROJECT_ID}-bastion-vm"
  project                   = var.PROJECT_ID
  zone                      = var.ZONE
  machine_type              = "f1-micro"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  metadata_startup_script = <<EOF
apt -qq update       &&
apt -qq upgrade -y
EOF

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


//
// ====================================================================
// Kube:
// ====================================================================
//


resource "google_container_cluster" "cluster" {
  name       = "${var.PROJECT_ID}-gke"
  project    = var.PROJECT_ID
  location   = var.REGION
  network    = google_compute_network.vpc.self_link
  subnetwork = google_compute_subnetwork.subnetwork.self_link

  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/16"
    services_ipv4_cidr_block = "/22"
  }

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}


output "cluster-name" {
  value = google_container_cluster.cluster.name
}


resource "google_container_node_pool" "node-pool-primary" {
  name     = "${var.PROJECT_ID}-node-pool-primary"
  project  = var.PROJECT_ID
  location = var.REGION
  cluster  = google_container_cluster.cluster.name

  node_count     = 1

  node_config {
    preemptible  = false
    machine_type = "n1-standard-1"
    disk_size_gb = 32
    metadata     = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",]
  }
}


// gcloud container clusters get-credentials $(terraform output cluster-name) --region $TF_VAR_REGION
