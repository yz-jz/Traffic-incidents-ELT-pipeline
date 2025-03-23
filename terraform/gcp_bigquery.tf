# Provision bigQuery dataset
#
resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.dataset_name
  friendly_name = "traffic incidents"
  location = var.location
  description = "This dataset is structured to support ingested data, staging tables, transformed views and analytics"
  # Enable content deletion when running terraform destroy
  delete_contents_on_destroy = true
}
