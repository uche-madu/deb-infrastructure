# VPC Settings
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 7.3.0"

  project_id   = var.project_id
  network_name = var.network_name

  subnets = [
    {
      subnet_name   = "deb-sub1"
      subnet_ip     = "10.10.10.0/24"
      subnet_region = var.region
    },
  ]

  secondary_ranges = {
    deb-sub1 = [
      {
        range_name    = "deb-sub1-secondary-gke-pods"
        ip_cidr_range = "10.10.11.0/24"
      },
      {
        range_name    = "deb-sub1-secondary-gke-services"
        ip_cidr_range = "10.10.21.0/24"
      },
    ]
  }
}

