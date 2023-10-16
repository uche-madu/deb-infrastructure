# google_client_config must be explicitly specified like the following.
data "google_client_config" "default" {}

# Random input generator
resource "random_id" "suffix" {
  byte_length = 8
}

# GKE Settings
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "~> 27.0.0"

  project_id            = module.vpc.project_id
  name                  = "${var.gke_cluster}-${random_id.suffix.hex}"
  region                = var.region
  zones                 = [var.zone]
  network               = module.vpc.network_name
  subnetwork            = module.vpc.subnets_names[0]
  ip_range_pods         = "deb-sub1-secondary-gke-pods"
  ip_range_services     = "deb-sub1-secondary-gke-services"
  identity_namespace    = "enabled"
  grant_registry_access = true

  node_pools = [
    {
      name               = var.node_pool_name
      machine_type       = var.machine_type
      node_locations     = var.zone
      min_count          = 1
      max_count          = 2
      disk_size_gb       = 30
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      service_account    = data.google_service_account.deb-sa.email
      preemptible        = false
      initial_node_count = 1
    },
  ]

  # https://cloud.google.com/artifact-registry/docs/access-control
  # https://cloud.google.com/sdk/gcloud/reference/container/clusters/create#:~:text=the%20node%20identity.-,Scopes%20options.,-%2D%2Dscopes%3D%5BSCOPE
  # Note that adding a new scope would recreate the node pool
  node_pools_oauth_scopes = {
    all = [
      "cloud-platform",
    ]
  }
}

# Install ArgoCD on GKE
resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = var.argocd_namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.46.8"

  depends_on = [module.gke.endpoint]

  values = [
    file("${path.module}/../argocd-app/values.yaml")
  ]
}

module "airflow_workload_identity" {
  source                      = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  name                        = "airflow"
  namespace                   = var.airflow_namespace
  project_id                  = var.project_id
  impersonate_service_account = data.google_service_account.deb-sa.email
  depends_on                  = [helm_release.argocd]

}