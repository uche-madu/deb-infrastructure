terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.81.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
  }

  # Note that when using the gcs backend, you’ll need to explicitly tell it to 
  # impersonate a service account using the impersonate_service_account argument.
  # Also values in this block cannot be variables and so must be hard-coded.
  backend "gcs" {
    bucket                      = "deb-capstone"
    prefix                      = "terraform/state"
    impersonate_service_account = "deb-sa@wizeline-deb.iam.gserviceaccount.com"
  }
}


