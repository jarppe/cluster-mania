resource "google_container_cluster" "cluster" {
  name       = var.PROJECT_ID
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
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  //  private_cluster_config {
  //    enable_private_nodes    = true
  //    enable_private_endpoint = false
  ////    master_global_access_config {
  ////      enabled = true
  ////    }
  //  }
  //
  release_channel {
    channel = "RAPID"
  }
}

resource "google_container_node_pool" "node-pool-primary" {
  name     = "${var.PROJECT_ID}-node-pool-primary"
  project  = var.PROJECT_ID
  location = var.REGION
  cluster  = google_container_cluster.cluster.name

  node_count = 1

  node_config {
    preemptible  = false
    machine_type = "n1-standard-1"
    disk_size_gb = 32
    metadata     = {
      disable-legacy-endpoints = "true"
    }

    tags = [
      "node",
      "node-primary"]

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append"]
  }

}

// Figure out why this works:
//   gcloud compute addresses create ingress-ip --global
// but this does not:
//
//resource "google_compute_address" "ingress-address" {
//  name         = "${var.PROJECT_ID}-ingress-ip"
//  project      = var.PROJECT_ID
//  region       = var.REGION
//  subnetwork   = google_compute_subnetwork.subnetwork.self_link
//  network_tier = "PREMIUM"
//  description  = "Public static IP for ${var.PROJECT_ID} ingress"
//}
//
//output "ingress-ip" {
//  value = google_compute_address.ingress-address.address
//}
//

// gcloud container clusters get-credentials $TF_VAR_PROJECT_ID --region $TF_VAR_REGION
