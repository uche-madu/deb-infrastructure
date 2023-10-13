locals {
  connection_url = "postgresql://${var.db_user}:${data.google_secret_manager_secret_version.db_user_pass.secret_data}@${module.sql-db.private_ip_address}:${var.db_port}/${var.airflow_database}"
}