
# Configure terraform to impersonate the project service account
# created in setup.sh. This is to avoid using service account keys directly as they
# are long-lived and 

# This provider will run in the context of your personal google account
provider "google" {
  alias = "impersonation"
  scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

# Retrieve the short-lived access token which will be used to authenticate 
# as the target service account (created in setup.sh). Note that the service 
# account has to be hard-coded, same as in the remote state config in main.tf.
data "google_service_account_access_token" "default" {
  provider               = google.impersonation
  target_service_account = "deb-sa@wizeline-deb.iam.gserviceaccount.com"
  scopes                 = ["userinfo-email", "cloud-platform"]
}

# This provider will use the access token of the service account. 
# It doesn’t have an alias, meaning it’ll be the default provider
# that will be used by all terraform code across this project
provider "google" {
  # credentials = file(var.credentials_file)
  access_token = data.google_service_account_access_token.default.access_token
  project      = var.project_id
  region       = var.region
  zone         = var.zone
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${module.gke.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  }
}
