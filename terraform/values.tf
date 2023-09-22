locals {
  rendered_values = templatefile("${path.cwd}/airflow-helm-values/values.override.yaml.tftpl", {
    db_password = data.google_secret_manager_secret_version.db_user_pass.secret_data,
    db_host     = module.sql-db.private_ip_address
  })
}