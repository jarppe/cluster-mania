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
