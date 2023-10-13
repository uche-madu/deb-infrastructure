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

# Airflow Fernet Key
resource "null_resource" "generate_fernet_key" {
  provisioner "local-exec" {
    command = "python ../generate-fernet-key.py > ../fernet-key.txt"
  }
}

data "external" "fernet_key" {
  program    = ["python", "${path.module}/../generate-fernet-key.py"]
  depends_on = [null_resource.generate_fernet_key]
}

resource "google_secret_manager_secret" "fernet_key" {
  secret_id = "fernet-key"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "fernet_key_version" {
  secret      = google_secret_manager_secret.fernet_key.name
  secret_data = data.external.fernet_key.result["fernet_key"]

  lifecycle {
    ignore_changes = [secret_data]
  }
}

# Retrieve the fernet key
data "google_secret_manager_secret_version" "fernet_key_version" {
  secret  = google_secret_manager_secret.fernet_key.name
  version = "latest"

  depends_on = [google_secret_manager_secret_version.fernet_key_version]
}

# GitSync Ssh key
# Fetch the latest version of the secret. The secret was created in setup.sh
data "google_secret_manager_secret_version" "airflow_ssh_key_private" {
  secret  = "airflow_ssh_key_private"
  version = "latest"
}

# ArgoCD Ssh key
# Fetch the latest version of the secret. The secret was created in setup.sh
data "google_secret_manager_secret_version" "argocd_ssh_key_private" {
  secret  = "argocd_ssh_key_private"
  version = "latest"
}

# DEB service account key
resource "google_secret_manager_secret" "deb_sa_key_secret" {
  secret_id = "deb_sa_key_secret"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "deb_sa_key_secret_version" {
  secret      = google_secret_manager_secret.deb_sa_key_secret.id
  secret_data = google_service_account_key.deb_sa_key.private_key
}

# Fetch the latest version of the secret.
data "google_secret_manager_secret_version" "deb_sa_key_secret_version" {
  secret  = "deb_sa_key_secret"
  version = "latest"

  depends_on = [google_secret_manager_secret_version.deb_sa_key_secret_version]
}
