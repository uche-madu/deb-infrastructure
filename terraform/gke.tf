# google_client_config must be explicitly specified like the following.
data "google_client_config" "default" {}

# Retrieve the service account established in setup.sh
data "google_service_account" "deb-sa" {
  account_id = "deb-sa"
}

# Random input generator
resource "random_id" "suffix" {
  byte_length = 8
}

# GKE Settings
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "~> 27.0.0"

  project_id        = module.vpc.project_id
  name              = "${var.gke_cluster}-${random_id.suffix.hex}"
  region            = var.region
  zones             = [var.zone]
  network           = module.vpc.network_name
  subnetwork        = module.vpc.subnets_names[0]
  ip_range_pods     = "deb-sub1-secondary-gke-pods"
  ip_range_services = "deb-sub1-secondary-gke-services"

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
  # Note that storage-ro scope is required to pull images from artifact registry
  # (the custom airflow image in this project's use-case) 
  # Note that adding a new scope would recreate the node pool
  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "storage-ro",
    ]
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = var.argocd_namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.46.7"

  depends_on = [module.gke.endpoint]

  values = [
    file("${path.module}/../argocd-app/values.yaml")
  ]
}

# Helm Airflow
# resource "helm_release" "airflow" {
#   name       = "airflow"
#   repository = "https://airflow.apache.org"

#   # Previously had to pull the helm chart via the CLI locally and reference 
#   # the local directory ("./airflow") here because the Chart.yaml file in the 
#   # remote repo was missing (probably a provider issue).
#   # The fix was to ensure there was no directory with the same name as the chart.
#   # I had an "airflow" directory while the chart name is also "airflow". 
#   # This is a general issue with the helm_release resource. 
#   chart            = "airflow"
#   namespace        = kubernetes_namespace.airflow.metadata[0].name
#   version          = var.airflow_helm_version
#   create_namespace = false
#   wait             = false # Setting to true would impair the wait-for-airflow-migrations container

#   values = [file("${path.cwd}/airflow-helm-values/values-dev.yaml"), local.rendered_values]

#   depends_on = [module.gke.endpoint]

# }
