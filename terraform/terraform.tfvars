project_id = "wizeline-deb"
region     = "us-central1"
zone       = "us-central1-c"
# zones      = ["us-central1-a", "us-central1-b", "us-central1-c"]

# VPC
network_name = "deb-capstone-net"
subnet-01    = "deb-sub1"
subnet-02    = "deb-sub2"

# GKE
gke_cluster    = "deb-airflow-cluster"
node_pool_name = "deb-node-pool"
machine_type   = "n1-standard-2"
node_count     = 1

# Services
enable_apis                 = true
disable_services_on_destroy = false
disable_dependent_services  = false

# Helm
airflow_helm_version = "1.10.0"
airflow_namespace    = "airflow"
argocd_namespace     = "argocd"

# Cloud SQL
db_tier          = "db-f1-micro"
airflow_database = "deb-airflow-db"
db_user          = "postgres0"
db_port          = 5432
db_disk_size_gb  = 10
instance_name    = "deb-sql-instance"
