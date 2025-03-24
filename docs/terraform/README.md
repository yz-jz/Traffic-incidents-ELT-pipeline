# Cloud Provisionning

This section of the project uses Terraform to provision cloud infrastructure resources. It includes configuration for creating and managing resources such as storage buckets, virtual machines, and other GCP services required for the project's deployment.

## Provisionned resources :
### 1. DataLake bucket : Terraform creates data lake bucket for storage of raw extracted data before loading to BigQuery
```terraform 
resource "google_storage_bucket" "datalake_bucket" {
  name = var.datalake_bucket_name
  location = var.location
  # Force destory to enable destruction when bucket is not empty
  force_destroy = true
}
```
### 2. Deployment bucket : Terraform creates a bucket and uploads source code necessary for airflow deployment
```terraform 
resource "google_storage_bucket" "deployment_bucket" {
  name = var.deployment_bucket_name
  location = var.location
  # Force destory to enable destruction when bucket is not empty
  force_destroy = true
}


resource "google_storage_bucket_object" "compute_engine_folder" {
  name = "src.zip"
  source = "../src.zip"
  content_type = "application/zip"
  bucket = google_storage_bucket.deployment_bucket.name
}
```
### 3. BigQuery Dataset: Terraform creates dataset as a centralized location where structured and semi-structured data can be stored, processed, and queried.

```terraform
resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.dataset_name
  friendly_name = "traffic incidents"
  location = var.location
  description = "This dataset is structured to support ingested data, staging tables, transformed views and analytics"
  # Enable content deletion when running terraform destroy
  delete_contents_on_destroy = true
}
```
Compute instance: Terraform creates compute instance to host airflow, it also installs required dependencies, initialises the airflow project and starts the DAGs 

```terraform
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
  # Ensure compute instance is provisioned after gcs deployment bucket
  depends_on = [google_storage_bucket.deployment_bucket]
}
```
Compute instance handles docker installation, astro cli for airflow cosmos project,
downloads source code for dags from gcs bucket :

```bash
sudo apt update -y 
sudo apt install docker.io -y 
sudo apt install unzip -y 

curl -sSL install.astronomer.io | sudo bash -s
gsutil cp 'gs://${google_storage_bucket.deployment_bucket.name}/src.zip' /home/airflow
cd /home/airflow
unzip src.zip && cd src/airflow && yes | astro dev init && sudo astro dev start --wait 30m
```
### 4. Firewall rule: Enabling port forwarding to access **airflow UI** on port **8080**

```terraform
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


```
