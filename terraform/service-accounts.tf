# resource "google_service_account_key" "deb_sa_key" {
#   service_account_id = data.google_service_account.deb-sa.email
# }

# Retrieve the service account established in setup.sh
data "google_service_account" "deb-sa" {
  account_id = "deb-sa"
}


resource "google_service_account_iam_binding" "impersonate_binding" {
  service_account_id = module.airflow_workload_identity.gcp_service_account_fqn
  role               = "roles/iam.serviceAccountTokenCreator"

  members = [
    "serviceAccount:${data.google_service_account.deb-sa.email}"
  ]
}
