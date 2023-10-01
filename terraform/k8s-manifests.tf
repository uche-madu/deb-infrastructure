# ArgoCD ApplicationSet
resource "kubernetes_manifest" "applicationset" {
  provider   = kubernetes
  manifest   = yamldecode(file("${path.module}/../argocd-app/multi-app/applicationset.yaml"))
  depends_on = [helm_release.argocd]
}
