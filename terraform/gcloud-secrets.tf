# Google Cloud Secrets

# Random value generators
resource "random_id" "db_user_pass" {
  byte_length = 8
}

resource "random_id" "airflow_webserver_secret" {
  byte_length = 8
}

# DB user password
resource "google_secret_manager_secret" "db_user_pass" {
  secret_id = "db-user-pass-${random_id.suffix.hex}"

  replication {
    automatic = true
  }

  depends_on = [module.services.enabled_api_identities]
}

resource "google_secret_manager_secret_version" "db_user_pass" {
  secret      = google_secret_manager_secret.db_user_pass.id
  secret_data = random_id.db_user_pass.hex
}

# Use the data block to get the latest version of the random user password
data "google_secret_manager_secret_version" "db_user_pass" {
  secret  = google_secret_manager_secret.db_user_pass.secret_id
  version = "latest"

  depends_on = [google_secret_manager_secret_version.db_user_pass]
}


# Airflow webserver
resource "google_secret_manager_secret" "airflow_webserver_secret" {
  secret_id = "airflow-webserver-secret"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "airflow_webserver_secret_v1" {
  secret      = google_secret_manager_secret.airflow_webserver_secret.name
  secret_data = random_id.airflow_webserver_secret.hex
}

# Fetch the latest version of the secret
data "google_secret_manager_secret_version" "airflow_webserver_secret" {
  secret  = google_secret_manager_secret.airflow_webserver_secret.secret_id
  version = "latest"

  depends_on = [google_secret_manager_secret_version.airflow_webserver_secret_v1]
}

# GitSync Ssh key
# Fetch the latest version of the secret. The secret was created in setup.sh
data "google_secret_manager_secret_version" "airflow_ssh_key_private" {
  secret  = "airflow_ssh_key_private"
  version = "latest"
}

