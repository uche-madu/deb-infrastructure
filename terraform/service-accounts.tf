# resource "google_service_account_key" "deb_sa_key" {
#   service_account_id = data.google_service_account.deb-sa.email
# }

# Retrieve the service account established in setup.sh
data "google_service_account" "deb-sa" {
  account_id = "deb-sa"
}

resource "google_service_account" "airflow_worker_workload_identity_sa" {
  account_id   = "airflow-worker-wi-sa"
  display_name = "GSA for Airflow Worker Component GKE workload identity"
}

resource "google_service_account" "airflow_scheduler_workload_identity_sa" {
  account_id   = "airflow-scheduler-wi-sa"
  display_name = "GSA for Airflow Scheduler Component GKE workload identity"
}

# Allows for service account impersonation
resource "google_service_account_iam_binding" "airflow_worker_gsa_impersonation" {
  service_account_id = google_service_account.airflow_worker_workload_identity_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"

  members = [
    "serviceAccount:${data.google_service_account.deb-sa.email}"
  ]
}

resource "google_service_account_iam_binding" "airflow_scheduler_gsa_impersonation" {
  service_account_id = google_service_account.airflow_scheduler_workload_identity_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"

  members = [
    "serviceAccount:${data.google_service_account.deb-sa.email}"
  ]
}
