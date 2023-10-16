# resource "google_service_account_key" "deb_sa_key" {
#   service_account_id = data.google_service_account.deb-sa.email
# }

# Retrieve the service account established in setup.sh
data "google_service_account" "deb-sa" {
  account_id = "deb-sa"
}