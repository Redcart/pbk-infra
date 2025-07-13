module "enabled_google_apis" {
  source     = "terraform-google-modules/project-factory/google//modules/project_services"
  project_id = var.project_id
  activate_apis = [
    "iam.googleapis.com",
    "cloudscheduler.googleapis.com",
    "composer.googleapis.com",
    "cloudfunctions.googleapis.com",
    "run.googleapis.com",
    "eventarc.googleapis.com"
  ]
  disable_services_on_destroy = false
}

resource "google_project_iam_audit_config" "storage_audit_logs" {
  project = var.project_id
  service = "storage.googleapis.com"

  audit_log_config {
    log_type = "DATA_READ" # Enable data read access logs
  }

  audit_log_config {
    log_type = "DATA_WRITE" # Enable data write access logs
  }

  # Optional: Enable Admin Activity logs (for admin actions)
  # audit_log_configs {
  #   log_type = "ADMIN_READ"
  #   enable = true
  # }
  # audit_log_configs {
  #   log_type = "ADMIN_WRITE"
  #   enable = true
  # }
}