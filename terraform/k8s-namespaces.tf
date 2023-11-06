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

# Delete finalizer on terraform destroy
resource "null_resource" "remove_finalizers" {
  depends_on = [kubernetes_namespace.argocd]

  provisioner "local-exec" {
    when       = destroy
    command    = <<-EOT
      kubectl get namespace ${self.triggers.namespace} -o json | \
      jq '.metadata.finalizers = []' | \
      kubectl replace --raw "/api/v1/namespaces/${self.triggers.namespace}/finalize" -f -
    EOT
    on_failure = continue
  }

  triggers = {
    namespace = var.argocd_namespace
  }
}


# NFS namespace
# resource "kubernetes_namespace" "nfs" {
#   metadata {
#     name = var.nfs_namespace
#   }
# }