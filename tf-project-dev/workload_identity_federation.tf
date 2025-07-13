resource "google_iam_workload_identity_pool" "github_wip" {
  project                   = var.project_id
  workload_identity_pool_id = "github-wip"
  display_name              = "github-wip"
  description               = "Workload Identity pool for github actions"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_wip.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "attribute.repository == assertion.repository"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}