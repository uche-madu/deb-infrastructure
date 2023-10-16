# Airflow namespace
resource "kubernetes_namespace" "airflow" {
  metadata {
    name = var.airflow_namespace
  }
}

# ArgoCD namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
  }
}

# NFS namespace
# resource "kubernetes_namespace" "nfs" {
#   metadata {
#     name = var.nfs_namespace
#   }
# }