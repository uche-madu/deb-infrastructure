# Services

# Needs to be created before other services
module "cloudresourcemanager_service" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 14.3"

  project_id                  = var.project_id
  enable_apis                 = var.enable_apis
  disable_services_on_destroy = var.disable_services_on_destroy
  disable_dependent_services  = var.disable_dependent_services

  activate_apis = [
    "cloudresourcemanager.googleapis.com",
  ]
}

module "services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 14.3"

  project_id                  = module.cloudresourcemanager_service.project_id
  enable_apis                 = var.enable_apis
  disable_services_on_destroy = var.disable_services_on_destroy
  disable_dependent_services  = var.disable_dependent_services

  activate_apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "secretmanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "storage-component.googleapis.com",
    "dataproc.googleapis.com",
    "iamcredentials.googleapis.com",
    "bigquery.googleapis.com",
  ]
}