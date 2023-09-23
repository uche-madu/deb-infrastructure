resource "google_artifact_registry_repository" "docker_repository" {
  location      = var.region
  repository_id = "deb-capstone-airflow-gke"
  description   = "Wizeline DEB docker repository for custom airflow images"
  format        = "DOCKER"
}
