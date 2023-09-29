
# resource "kubernetes_config_map" "airflow_metadata_connection" {
#   metadata {
#     name      = "db-config"
#     namespace = kubernetes_namespace.airflow.metadata[0].name
#   }

#   data = {
#     user     = var.db_user
#     protocol = "postgresql"
#     host     = module.sql-db.private_ip_address
#     port     = var.db_port
#     db       = var.airflow_database
#     sslmode  = "disable"
#   }
# }


