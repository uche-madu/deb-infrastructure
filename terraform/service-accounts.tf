# resource "google_service_account_key" "deb_sa_key" {
#   service_account_id = data.google_service_account.deb-sa.email
# }

# Retrieve the service account established in setup.sh
data "google_service_account" "deb-sa" {
  account_id = "deb-sa"
}

resource "google_service_account" "airflow_workload_identity_sa" {
  account_id   = "airflow-wi-sa"
  display_name = "GSA for Airflow GKE workload identity"
}

# Allows for service account impersonation
resource "google_service_account_iam_binding" "impersonate_binding" {
  service_account_id = google_service_account.airflow_workload_identity_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"

  members = [
    "serviceAccount:${data.google_service_account.deb-sa.email}"
  ]
}
