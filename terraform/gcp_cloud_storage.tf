# Provision buckets for data storage & code uploads (cloud function)
#
# Bucket for parquet files
resource "google_storage_bucket" "datalake_bucket" {
  name = var.datalake_bucket_name
  location = var.location
  # Force destory to enable destruction when bucket is not empty
  force_destroy = true
}

# Bucket for source code
resource "google_storage_bucket" "deployment_bucket" {
  name = var.deployment_bucket_name
  location = var.location
  force_destroy = true
}

# Cloud functions bucket
# Source codes 
#resource "google_storage_bucket" "cloud_function_bucket" {
#  name = var.cloud_function_bucket_name
#  location = var.location
#  force_destroy = true
#}

# Folder for airflow deployment
resource "google_storage_bucket_object" "compute_engine_folder" {
  name = "src.zip"
  source = "../src.zip"
  content_type = "application/zip"
  bucket = google_storage_bucket.deployment_bucket.name
}


