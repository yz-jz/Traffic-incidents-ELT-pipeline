# Provision compute instance for airlow deployment

resource "google_compute_instance" "default" {
  name         = "airlow-instance"
  #machine_type = "e2-medium"
  machine_type = "n2-standard-2"
  zone         =  var.zone

  # Tag used for firewall rule
  tags = ["airflow"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  # Allow ssh connection to compute instance
  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_key)}"
  }

  # Attach service account to enable interaction with gcs
  # service account should have the required roles in order to work properly
  service_account {
    email = "${var.service_account}@${var.project_id}.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  # Run script on startup to launch airflow
  # Installs docker, astronomer cli
  # downloads all necessary files
  metadata_startup_script = <<-EOT
    #!/bin/bash
    sudo apt update -y 
    sudo apt install docker.io -y 
    sudo apt install unzip -y 

    curl -sSL install.astronomer.io | sudo bash -s
    gsutil cp "gs://${google_storage_bucket.deployment_bucket.name}/src.zip" /home/airflow
    cd /home/airflow
    unzip src.zip && cd src/airflow && yes | astro dev init && sudo astro dev start --wait 30m
  EOT
  # Ensure compute instance is provisioned after gcs deployment bucket
  depends_on = [google_storage_bucket.deployment_bucket]
}

# Set firewall rule to allow access to airflow's UI through 8080
resource "google_compute_firewall" "allow_airflow" {
  name = "airflow"
  network = "default"

  allow {
    protocol = "tcp"
    ports = ["8080"]
  }

  # Reference the compute instance tag to apply firewall rule
  target_tags = ["airflow"]
  source_ranges = [var.ip_address]
}

