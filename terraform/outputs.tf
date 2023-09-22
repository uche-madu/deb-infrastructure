output "network_name" {
  value = module.vpc.network_name
}
output "subnets_ips" {
  value = module.vpc.subnets_ips
}

# Cloud SQL
output "sql_instance_name" {
  description = "The name of the Cloud SQL instance."
  value       = module.sql-db.instance_name
}

output "instance_connection_name" {
  description = "The connection name of the Cloud SQL instance to be used in connection strings."
  value       = module.sql-db.instance_connection_name
}

output "additional_users" {
  description = "List of additional users associated with the Cloud SQL instance."
  value       = module.sql-db.additional_users
  sensitive   = true
}

output "private_ip_address" {
  description = "The private IP address of the Cloud SQL instance."
  value       = module.sql-db.private_ip_address
}

output "sql_instance_self_link" {
  description = "Self link of the Cloud SQL instance."
  value       = module.sql-db.instance_self_link
}

output "sql_service_account_email" {
  description = "Service account email associated with the Cloud SQL instance."
  value       = module.sql-db.instance_service_account_email_address
}


# GKE Cluster
output "gke_cluster_endpoint" {
  description = "Endpoint for the GKE cluster."
  value       = module.gke.endpoint
  sensitive   = true
}

output "gke_cluster_name" {
  description = "Name of the GKE cluster"
  value       = module.gke.name
}

output "gke_cluster_location" {
  description = "The region of the GKE cluster"
  value       = module.gke.location
}

# Services
output "enabled_apis" {
  description = "List of enabled APIs in the project."
  value       = module.services.enabled_apis
}
