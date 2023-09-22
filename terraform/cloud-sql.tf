# Cloud SQL

# module "private-service-access" {
#   source  = "GoogleCloudPlatform/sql-db/google//modules/private_service_access"
#   version = "~> 16.1.0"

#   project_id  = var.project_id
#   vpc_network = module.vpc.network_name

# } # Had to disable as there seems to be an error in the module configuration

# Create a static internal IP address for VPC peering between the our VPC and 
# the Google-managed Cloud SQL instance VPC
resource "google_compute_global_address" "private_ip_alloc" {
  name          = "private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.vpc.network_id
}

# Create a private connection
resource "google_service_networking_connection" "default" {
  network                 = module.vpc.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}

# Ensure that the static internal IP address is ready
resource "null_resource" "dependency_setter" {
  depends_on = [google_service_networking_connection.default]
}

module "sql-db" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version = "~> 16.1.0"

  name                 = "${var.instance_name}-${random_id.suffix.hex}"
  random_instance_name = false
  database_version     = "POSTGRES_15"
  project_id           = var.project_id
  zone                 = var.zone
  region               = var.region
  tier                 = var.db_tier
  disk_size            = var.db_disk_size_gb

  deletion_protection = false

  additional_databases = [
    {
      name      = var.airflow_database
      charset   = "UTF8"
      collation = "en_US.UTF8"
    },
  ]

  additional_users = [
    {
      name            = var.db_user
      password        = data.google_secret_manager_secret_version.db_user_pass.secret_data
      host            = "*"
      random_password = false
    }
  ]

  ip_configuration = {
    ipv4_enabled        = false
    private_network     = module.vpc.network_self_link
    require_ssl         = false
    allocated_ip_range  = google_compute_global_address.private_ip_alloc.name
    authorized_networks = []
  }

  module_depends_on = [null_resource.dependency_setter]
}