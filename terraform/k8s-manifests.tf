# ArgoCD ApplicationSet
# The cluster must already be running for this to work. Terraform apply has to be 
# run once to create the cluster before uncommenting this  and re-running terraform apply
# resource "kubernetes_manifest" "applicationset" {
#   provider   = kubernetes
#   manifest   = yamldecode(file("${path.module}/../argocd-app/multi-app/applicationset.yaml"))
#   depends_on = [helm_release.argocd]
# }
