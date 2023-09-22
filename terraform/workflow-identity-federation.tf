# resource "google_iam_workload_identity_pool" "pool" {
#   workload_identity_pool_id = "example-pool"
# }

# resource "google_iam_workload_identity_pool_provider" "github_actions" {
#   workload_identity_pool_id          = google_iam_workload_identity_pool.pool.workload_identity_pool_id
#   workload_identity_pool_provider_id = "example-prvdr"
#   display_name                       = "Github"
#   description                        = "Github Actions OIDC identity pool provider for CI/CD"
#   disabled                           = false
#   attribute_condition                = "assertion.repository=='uche/xxxxxx'"
#   attribute_mapping                  = {
#     "google.subject"                  = "assertion.sub"
#     "attribute.repository_id"                   = "assertion.repository_id"
#     "attribute.repository"                   = "assertion.repository"
#     "attribute.actor"                   = "assertion.actor"

#   }
#   oidc {
#     issuer_uri        = "https://token.actions.githubusercontent.com"
#   }
# }
