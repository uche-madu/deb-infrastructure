resource "google_artifact_registry_repository" "docker_repository" {
  location      = var.region
  repository_id = "deb-capstone"
  description   = "Wizeline DEB capstone project docker repository"
  format        = "DOCKER"
}
