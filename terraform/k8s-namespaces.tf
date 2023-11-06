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
    when = destroy
    command = <<-EOT
      kubectl get namespace ${var.argocd_namespace} -o json | \
      jq '.metadata.finalizers = []' | \
      kubectl replace --raw "/api/v1/namespaces/${var.argocd_namespace}/finalize" -f -
    EOT
    on_failure = continue
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}


# NFS namespace
# resource "kubernetes_namespace" "nfs" {
#   metadata {
#     name = var.nfs_namespace
#   }
# }