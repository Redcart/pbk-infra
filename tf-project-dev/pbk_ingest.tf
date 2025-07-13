### Ingestion ###

# Service Account for runtime
module "service_account_pbk_ingestion_runtime" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "~> 4.0"
  project_id = var.project_id
  names      = ["${var.sa_ingestion}"]
  project_roles = [
    "${var.project_id}=>roles/storage.objectAdmin",
    "${var.project_id}=>roles/bigquery.jobUser",
    "${var.project_id}=>roles/run.admin",
    "${var.project_id}=>roles/pubsub.editor",
    #"${var.project_id}=>roles/eventarc.eventReceiver"
  ]
}

resource "google_service_account_iam_member" "sa_pbk_ingest_runtime_sa_gh_cicd_user" {
  service_account_id = module.service_account_pbk_ingestion_runtime.service_account.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.sa_gh_cicd}@${var.project_id}.iam.gserviceaccount.com"
}

# Bucket of ingestion
module "gcs_bucket_pbk_ingestion" {
  source     = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version    = "~> 8.0"
  name       = var.gcs_pbk_ingestion_bucket_name
  project_id = var.project_id
  location   = var.global_region
  iam_members = [{
    role   = "roles/storage.objectUser"
    member = "serviceAccount:${module.service_account_pbk_ingestion_runtime.service_account.email}"
  }]

}

### Monolithic Cloud function

# Cloud Scheduler for stations (once a day) and bikes capacity (every 5 minutes)
resource "google_cloud_scheduler_job" "cs_pbk_stations" {
  paused           = true
  name             = var.cs_pbk_ingestion_stations
  description      = "cloud scheduler for etl publibike stations"
  schedule         = "0 6 * * *"
  time_zone        = "Europe/Zurich"
  attempt_deadline = "300s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-${var.project_id}.cloudfunctions.net/${var.cf_pbk_ingestion}"
    body        = base64encode("{\"mode\":\"stations\"}")
    headers = {
      "Content-Type" = "application/json"
    }
    oidc_token {
      audience              = "https://${var.region}-${var.project_id}.cloudfunctions.net/${var.cf_pbk_ingestion}"
      service_account_email = module.service_account_pbk_ingestion_runtime.service_account.email
    }
  }
}

resource "google_cloud_scheduler_job" "cs_pbk_bikes_capacity" {
  paused           = true
  name             = var.cs_pbk_ingestion_bikes
  description      = "cloud scheduler for etl publibike bikes capacity"
  schedule         = "*/5 * * * *"
  time_zone        = "Europe/Zurich"
  attempt_deadline = "300s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-${var.project_id}.cloudfunctions.net/${var.cf_pbk_ingestion}"
    body        = base64encode("{\"mode\":\"capacity\"}")
    headers = {
      "Content-Type" = "application/json"
    }
    oidc_token {
      audience              = "https://${var.region}-${var.project_id}.cloudfunctions.net/${var.cf_pbk_ingestion}"
      service_account_email = module.service_account_pbk_ingestion_runtime.service_account.email
    }
  }
}

### 3 decoupled cloud functions with pubsub

# Cloud Scheduler for stations (once a day) and bikes capacity (every 5 minutes)
resource "google_cloud_scheduler_job" "cs_pbk_stations_decoupled" {
  paused           = false
  name             = var.cs_pbk_ingestion_stations_decoupled
  description      = "cloud scheduler for extract publibike stations"
  schedule         = "0 6 * * *"
  time_zone        = "Europe/Zurich"
  attempt_deadline = "300s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-${var.project_id}.cloudfunctions.net/${var.cf_pbk_extract_decoupled}"
    body        = base64encode("{\"mode\":\"stations\"}")
    headers = {
      "Content-Type" = "application/json"
    }
    oidc_token {
      audience              = "https://${var.region}-${var.project_id}.cloudfunctions.net/${var.cf_pbk_extract_decoupled}"
      service_account_email = module.service_account_pbk_ingestion_runtime.service_account.email
    }
  }
}

resource "google_cloud_scheduler_job" "cs_pbk_bikes_capacity_decoupled" {
  paused           = false
  name             = var.cs_pbk_ingestion_bikes_decoupled
  description      = "cloud scheduler for extract publibike bikes capacity"
  schedule         = "*/5 * * * *"
  time_zone        = "Europe/Zurich"
  attempt_deadline = "300s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-${var.project_id}.cloudfunctions.net/${var.cf_pbk_extract_decoupled}"
    body        = base64encode("{\"mode\":\"capacity\"}")
    headers = {
      "Content-Type" = "application/json"
    }
    oidc_token {
      audience              = "https://${var.region}-${var.project_id}.cloudfunctions.net/${var.cf_pbk_extract_decoupled}"
      service_account_email = module.service_account_pbk_ingestion_runtime.service_account.email
    }
  }
}

# BigQuery Dataset for ingesting source data retrieved from API
resource "google_bigquery_dataset" "big_query_dataset_ingestion" {
  dataset_id    = var.bq_pbk_ingestion_dataset
  friendly_name = var.bq_pbk_ingestion_dataset
  description   = "BigQuery Dataset used for Publibike data retrieved from API"
  location      = "EU"

}

resource "google_bigquery_dataset_iam_member" "sa_composer_editor_ingestion_dataset" {
  dataset_id = google_bigquery_dataset.big_query_dataset_ingestion.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${module.service_account_pbk_ingestion_runtime.service_account.email}"
}

# BigQuery Tables for stations and bikes capacity

resource "google_bigquery_table" "big_query_table_ingestion_stations" {
  dataset_id = google_bigquery_dataset.big_query_dataset_ingestion.dataset_id
  table_id   = var.bq_pbk_ingestion_stations_table

  schema = <<EOF
[
  {
    "name": "station_id",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "ID of the station"
  },
  {
    "name": "latitude",
    "type": "FLOAT64",
    "mode": "NULLABLE",
    "description": "Latitude of the station"
  },
  {
    "name": "longitude",
    "type": "FLOAT64",
    "mode": "NULLABLE",
    "description": "Longitude of the station"
  },
  {
    "name": "state_id",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "State ID of the station"
  },
  {
    "name": "state_name",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "State name of the station"
  },
  {
    "name": "name",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Name of the station"
  },
  {
    "name": "address",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Address of the station"
  },
  {
    "name": "zip",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Zip code of the station"
  },
  {
    "name": "city",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "City of the station"
  },
  {
    "name": "network_id",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Network ID of the station"
  },
  {
    "name": "network_name",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Network name of the station"
  },
  {
    "name": "is_virtual_station",
    "type": "BOOL",
    "mode": "NULLABLE",
    "description": "Virtual station (True or False)"
  },
  {
    "name": "capacity",
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

resource "google_bigquery_table" "big_query_table_ingestion_bikes_capacity" {
  dataset_id = google_bigquery_dataset.big_query_dataset_ingestion.dataset_id
  table_id   = var.bq_pbk_ingestion_bikes_capacity_table

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
    "name": "vehicle_id",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "ID of the bike"
  },
  {
    "name": "vehicle_name",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Name of the bike"
  },
  {
    "name": "vehicle_ebike_battery_level",
    "type": "FLOAT64",
    "mode": "NULLABLE",
    "description": "Battery level (out of 100) if electric bike"
  },
  {
    "name": "vehicle_type_id",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "ID type of bike"
  },
  {
    "name": "vehicle_type_name",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Name type of bike"
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

# PubSub topic

resource "google_pubsub_topic" "pub_sub_topic_transformation" {
  name                       = "transformation"
  message_retention_duration = "86600s"
}


resource "google_pubsub_topic" "pub_sub_topic_ingestion" {
  name                       = "ingestion"
  message_retention_duration = "86600s"
}

# Envent arc trigger from file created in GCS
# Grant the Cloud Storage service account permission to publish pub/sub topics
data "google_storage_project_service_account" "gcs_account" {}

resource "google_project_iam_member" "pubsubpublisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

resource "google_project_iam_member" "sa_compute_engine_eventarc_receiver" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

module "service_account_pbk_composer" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "~> 4.0"
  project_id = var.project_id
  names      = ["${var.sa_composer}"]
  project_roles = [
    "${var.project_id}=>roles/composer.worker",
    "${var.project_id}=>roles/bigquery.jobUser"
  ]
}

# Bucket for composer 3
module "gcs_bucket_pbk_composer" {
  source     = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version    = "~> 8.0"
  name       = var.gcs_pbk_composer_bucket_name
  project_id = var.project_id
  location   = var.region
  iam_members = [{
    role   = "roles/storage.objectUser"
    member = "serviceAccount:${module.service_account_pbk_composer.service_account.email}"
  }]

}