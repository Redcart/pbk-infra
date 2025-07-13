### dbt ###

# Service Account for runtime
module "service_account_pbk_dbt_runtime" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "~> 4.0"
  project_id = var.project_id
  names      = ["${var.sa_dbt}"]
  project_roles = [
    "${var.project_id}=>roles/storage.objectAdmin",
    "${var.project_id}=>roles/bigquery.jobUser",
    "${var.project_id}=>roles/run.admin",
  ]
}

resource "google_service_account_iam_member" "sa_pbk_dbt_runtime_sa_gh_cicd_user" {
  service_account_id = module.service_account_pbk_dbt_runtime.service_account.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.sa_gh_cicd}@${var.project_id}.iam.gserviceaccount.com"
}

# Bucket of dbt
module "gcs_bucket_pbk_dbt" {
  source     = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version    = "~> 8.0"
  name       = var.gcs_pbk_dbt_bucket_name
  project_id = var.project_id
  location   = var.global_region
  iam_members = [{
    role   = "roles/storage.objectUser"
    member = "serviceAccount:${module.service_account_pbk_dbt_runtime.service_account.email}"
  }]

}

### SQL transformation through cloud function

# Cloud Scheduler for transforming table (every hour)
resource "google_cloud_scheduler_job" "cs_pbk_dbt" {
  paused           = true
  name             = var.cs_pbk_dbt
  description      = "cloud scheduler for SQL transformation"
  schedule         = "0 * * * *"
  time_zone        = "Europe/Zurich"
  attempt_deadline = "300s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-${var.project_id}.cloudfunctions.net/${var.cf_pbk_dbt}"
    headers = {
      "Content-Type" = "application/json"
    }
    oidc_token {
      audience              = "https://${var.region}-${var.project_id}.cloudfunctions.net/${var.cf_pbk_dbt}"
      service_account_email = module.service_account_pbk_dbt_runtime.service_account.email
    }
  }
}

# BigQuery Dataset for ingesting source data retrieved from API
resource "google_bigquery_dataset" "big_query_dataset_dbt" {
  dataset_id    = var.bq_pbk_dbt_dataset
  friendly_name = var.bq_pbk_dbt_dataset
  description   = "BigQuery Dataset used for Publibike data consolidated"
  location      = "EU"

}

resource "google_bigquery_dataset_iam_member" "sa_composer_editor_dbt_dataset" {
  dataset_id = google_bigquery_dataset.big_query_dataset_dbt.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${module.service_account_pbk_dbt_runtime.service_account.email}"
}

# BigQuery Table

resource "google_bigquery_table" "big_query_table_dbt" {
  dataset_id = google_bigquery_dataset.big_query_dataset_dbt.dataset_id
  table_id   = var.bq_pbk_dbt_table

  time_partitioning {
    field = "ingestion_time"
    type  = "MONTH"
  }

  schema = <<EOF
[
  {
    "name": "station_id",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "ID of the station"
  },
  {
    "name": "nb_bikes_available_mechanic",
    "type": "INTEGER",
    "mode": "NULLABLE",
    "description": "Number of mechanic bikes available at the station"
  },
  {
    "name": "nb_bikes_available_electric",
    "type": "INTEGER",
    "mode": "NULLABLE",
    "description": "Number of electric bikes available at the station"
  },
  {
    "name": "nb_bikes_available",
    "type": "INTEGER",
    "mode": "NULLABLE",
    "description": "Number of bikes available at the station"
  },
  {
    "name": "ingestion_time",
    "type": "TIMESTAMP",
    "mode": "REQUIRED",
    "description": "Timestamp of the ingestion"
  }
]
EOF

}