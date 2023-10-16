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

# Airflow fernet key
resource "kubernetes_secret" "fernet_key_secret" {
  metadata {
    name      = "fernet-key-secret"
    namespace = kubernetes_namespace.airflow.metadata[0].name
  }

  data = {
    fernet-key = data.google_secret_manager_secret_version.fernet_key_version.secret_data
  }
}

# GitSync Ssh Key
resource "kubernetes_secret" "airflow_ssh_secret" {
  metadata {
    name      = "airflow-ssh-secret"
    namespace = kubernetes_namespace.airflow.metadata[0].name
  }

  data = {
    gitSshKey = data.google_secret_manager_secret_version.airflow_ssh_key_private.secret_data
  }
}

# Airflow Provider Connection
resource "kubernetes_secret" "airflow_gcp_connection" {
  metadata {
    name      = "airflow-gcp-connection"
    namespace = kubernetes_namespace.airflow.metadata[0].name
  }

  # Leaving the connection URI string because we're using Application Default Credentials
  # as were leveraging GKE workload identity 
  # https://airflow.apache.org/docs/apache-airflow-providers-google/stable/connections/gcp.html#note-on-application-default-credentials
  data = {
    AIRFLOW_CONN_GCP = "google-cloud-platform://"
  }
}

# Airflow metadataConnection
resource "kubernetes_secret" "airflow_db_connection_secret" {
  metadata {
    name      = "airflow-db-connection-secret"
    namespace = kubernetes_namespace.airflow.metadata[0].name
  }

  data = {
    connection            = local.connection_url,
    AIRFLOW_CONN_POSTGRES = local.connection_url
  }
}

# ArgoCD Ssh Key
resource "kubernetes_secret" "argocd_ssh_secret" {
  metadata {
    name      = "argocd-ssh-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  data = {
    sshPrivateKey = data.google_secret_manager_secret_version.argocd_ssh_key_private.secret_data
  }
}

# ArgoCD Repo Credentials
resource "kubernetes_secret" "argoproj_ssh_creds" {
  metadata {
    name      = "argoproj-ssh-creds"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }

  data = {
    url           = "git@github.com:uche-madu"
    type          = "git"
    sshPrivateKey = data.google_secret_manager_secret_version.argocd_ssh_key_private.secret_data
  }

  type = "Opaque"
}

# ArgoCD: Ssh Connection to the deb-infrastructure repo
resource "kubernetes_secret" "infra_ssh_repo" {
  metadata {
    name      = "infra-ssh-repo"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    url = "git@github.com:uche-madu/deb-infrastructure.git"
  }

  type = "Opaque"
}