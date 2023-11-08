variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "zones" {
  description = "The list of zones where the cluster nodes will be created"
  type        = list(string)
}

variable "network_name" {
  type = string
}

variable "subnet-01" {
  type = string
}

# variable "subnet-02" {
#   type = string
# }



# GKE
variable "gke_cluster" {
  type = string
}
variable "node_pool_name" {
  type = string
}
variable "machine_type" {
  type = string
}
variable "node_count" {
  type = number
}

variable "airflow-gke-workload-identity" {
  type = string
}


# Services
variable "enable_apis" {
  type = bool
}
variable "disable_services_on_destroy" {
  type = bool
}
variable "disable_dependent_services" {
  type = bool
}

# Helm
variable "airflow_helm_version" {
  type = string
}
variable "airflow_namespace" {
  type = string
}

variable "argocd_namespace" {
  type = string
}

variable "monitoring_namespace" {
  type = string
}

# variable "nfs_namespace" {
#   type = string
# }

# Cloud SQL
variable "instance_name" {
  description = "Name for the sql instance database"
  type        = string
}
variable "db_tier" {
  type    = string
  default = "db-f1-micro"
}
variable "airflow_database" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_port" {
  type = string
}

variable "db_disk_size_gb" {
  description = "Size of the disk in the sql instance"
  type        = number
}
