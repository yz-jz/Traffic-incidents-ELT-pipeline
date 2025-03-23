terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.25.0"
    }
  }
}

provider "google" {
    credentials = file(var.gcp_key)
    project = var.project_id
    region = var.region
    zone = var.zone
}

