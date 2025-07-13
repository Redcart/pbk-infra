resource "google_project_iam_member" "sa_terraform" {
  project = var.project_id
  for_each = toset([
    "roles/serviceusage.serviceUsageAdmin", # set up manually first to enable APIs
    "roles/iam.securityAdmin",              # set up manually first to get and set iam policies
    "roles/iam.serviceAccountAdmin",
    "roles/storage.admin",
    "roles/cloudfunctions.admin",
    "roles/cloudscheduler.admin",
    "roles/bigquery.admin",
    "roles/iam.workloadIdentityPoolAdmin",
    "roles/iam.serviceAccountUser",
    "roles/composer.admin",
    "roles/pubsub.admin",
    "roles/compute.viewer"
  ])
  role   = each.key
  member = "serviceAccount:${var.sa_terraform}"
}