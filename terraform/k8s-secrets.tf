# Airflow webserver
resource "kubernetes_secret" "airflow_webserver_secret" {
  metadata {
    name      = "airflow-webserver-secret"
    namespace = var.airflow_namespace
  }

  data = {
    webserver-secret-key = data.google_secret_manager_secret_version.airflow_webserver_secret.secret_data
  }
}

# GitSync ssh key
resource "kubernetes_secret" "airflow_ssh_secret" {
  metadata {
    name      = "airflow-ssh-secret"
    namespace = var.airflow_namespace
  }

  data = {
    gitSshKey = data.google_secret_manager_secret_version.airflow_ssh_key_private
  }
}

