
# Airflow webserver
resource "kubernetes_secret" "airflow_webserver_secret" {
  metadata {
    name      = "airflow-webserver-secret"
    namespace = kubernetes_namespace.airflow.metadata[0].name
  }

  data = {
    webserver-secret-key = data.google_secret_manager_secret_version.airflow_webserver_secret.secret_data
  }
}

# GitSync ssh key
resource "kubernetes_secret" "airflow_ssh_secret" {
  metadata {
    name      = "airflow-ssh-secret"
    namespace = kubernetes_namespace.airflow.metadata[0].name
  }

  data = {
    gitSshKey = data.google_secret_manager_secret_version.airflow_ssh_key_private.secret_data
  }
}

# Airflow Provider Connections
resource "kubernetes_secret" "airflow_gcp_connection" {
  metadata {
    name      = "airflow-gcp-connection"
    namespace = kubernetes_namespace.airflow.metadata[0].name
  }

  data = {
    AIRFLOW_CONN_GCP = "google-cloud-platform://?extra__google_cloud_platform__impersonation_chain=${urlencode(data.google_service_account.deb-sa.email)}&extra__google_cloud_platform__project=${urlencode(var.project_id)}"
  }
}

# Airflow metadataConnection
resource "kubernetes_secret" "airflow_db_password" {
  metadata {
    name      = "db-password"
    namespace = kubernetes_namespace.airflow.metadata[0].name
  }

  data = {
    db-password = data.google_secret_manager_secret_version.db_user_pass.secret_data
  }
}


