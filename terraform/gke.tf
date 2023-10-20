# google_client_config must be explicitly specified like the following.
data "google_client_config" "default" {}

# Random input generator
resource "random_id" "suffix" {
  byte_length = 8
}

resource "random_shuffle" "zones" {
  input        = var.zones
  result_count = 2 # to get two zones
}


# GKE Settings
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "~> 28.0.0"

  project_id            = module.vpc.project_id
  name                  = "${var.gke_cluster}-${random_id.suffix.hex}"
  region                = var.region
  zones                 = var.zones
  network               = module.vpc.network_name
  subnetwork            = module.vpc.subnets_names[0]
  ip_range_pods         = "deb-sub1-secondary-gke-pods"
  ip_range_services     = "deb-sub1-secondary-gke-services"
  grant_registry_access = true

  cluster_autoscaling = {
    "auto_repair" : true,
    "auto_upgrade" : true,
    "disk_size" : 32,
    "disk_type" : "pd-standard",
    "enabled" : true,
    "max_cpu_cores" : 12,
    "min_cpu_cores" : 1,
    "gpu_resources" : [],
    "max_memory_gb" : 15,
    "min_memory_gb" : 1
  }

  node_pools = [
    {
      name               = var.node_pool_name
      machine_type       = var.machine_type
      node_locations     = join(",", random_shuffle.zones.result)
      min_count          = 1
      max_count          = 3
      disk_size_gb       = 20
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

# GKE Workload identity
module "airflow_workload_identity" {
  source                      = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  name                        = "airflow"
  namespace                   = var.airflow_namespace
  project_id                  = var.project_id
  impersonate_service_account = data.google_service_account.deb-sa.email
  depends_on                  = [helm_release.argocd]
}

# Create NFS Storage
# resource "helm_release" "nfs" {
#   name = "nfs-client"
#   namespace = var.nfs_namespace
#   repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/"
#   chart      = "nfs-subdir-external-provisioner"

#   set {
#     name  = "nfs.server"
#     value = ""
#   }

#   set {
#     name  = "nfs.path"
#     value = ""
#   }

#   set {
#     name  = "storageClass.archiveOnDelete"
#     value = "false"
#   }
# }
