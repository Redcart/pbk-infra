### Service Account for github actions

module "service_account_pbk_github_actions_cicd" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "~> 4.0"
  project_id = var.project_id
  names      = ["${var.sa_gh_cicd}"]
  project_roles = [
    "${var.project_id}=>roles/cloudfunctions.developer",
    "${var.project_id}=>roles/run.admin",
    "${var.project_id}=>roles/storage.admin",
    "${var.project_id}=>roles/artifactregistry.writer",
    "${var.project_id}=>roles/composer.admin",
  ]
}

resource "google_service_account_iam_member" "sa_pbk_gh_project_account_user" {
  service_account_id = module.service_account_pbk_github_actions_cicd.service_account.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.sa_gh_cicd}@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_service_account_iam_member" "sa_pbk_gh_ingest_wi_user" {
  service_account_id = module.service_account_pbk_github_actions_cicd.service_account.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/github-wip/attribute.repository/Redcart/pbk-ingestion"
}

resource "google_service_account_iam_member" "sa_pbk_gh_dbt_wi_user" {
  service_account_id = module.service_account_pbk_github_actions_cicd.service_account.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/github-wip/attribute.repository/Redcart/pbk-dbt"
}

data "google_compute_default_service_account" "default" {
}

resource "google_service_account_iam_member" "sa_github_actions_cicd_compute" {
  service_account_id = data.google_compute_default_service_account.default.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.sa_gh_cicd}@${var.project_id}.iam.gserviceaccount.com"
}