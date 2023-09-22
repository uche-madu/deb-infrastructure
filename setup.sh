#!/bin/bash

# Retrieve the project ID
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $(gcloud config get-value core/project) --format=value\(projectNumber\))

export BUCKET_NAME="gs://deb-capstone"
# Check and create the GCS bucket with uniform access control if it doesn't exist
gsutil ls $BUCKET_NAME &> /dev/null || gsutil mb -l us -b on $BUCKET_NAME

# Create a Service Account
gcloud iam service-accounts create deb-sa \
    --display-name="DEB SA" \
    --description="Service Account for Wizeline Data Engineering Bootcamp"

# Generate and Download JSON Key
gcloud iam service-accounts keys create credentials.json \
    --iam-account="deb-sa@${PROJECT_ID}.iam.gserviceaccount.com"

# Set the Service Account Key File Environment Variable
# export GOOGLE_APPLICATION_CREDENTIALS=./credentials.json

# Create specific IAM Role bindings following the principle of least privilege

# Kubernetes Engine Role Binding:
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:deb-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/container.admin"

# Cloud Storage Role Binding
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:deb-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# Dataproc Role Binding
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:deb-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/dataproc.editor"

# Storage viewer Role Binding
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:deb-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.objectViewer"

# This allows the service account to generate access tokens for other 
# service accounts within the same project.
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:deb-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountTokenCreator"

# Configuring service account impersonation IAM bindings to allow the principal
# to impersonate the service account.
gcloud iam service-accounts add-iam-policy-binding \
    deb-sa@${PROJECT_ID}.iam.gserviceaccount.com \
    --member='user:uche.iheanyi.madu@gmail.com' \
    --role='roles/iam.serviceAccountTokenCreator'

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:deb-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/serviceusage.serviceUsageConsumer"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:deb-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/compute.networkAdmin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:deb-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountAdmin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:deb-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/serviceusage.serviceUsageAdmin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:deb-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:deb-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.securityAdmin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:deb-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/secretmanager.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:deb-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/cloudsql.admin"

# Setting up Workload Identity Federation for GitHub Actions by creating 
# a Workload Identity Pool and Workload Identity Provider
gcloud iam workload-identity-pools create "deb-pool" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="Wizeline DEB pool"

gcloud iam workload-identity-pools providers github-actions-oidc "my-provider" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="deb-pool" \
  --display-name="Github Actions" \
  --description="Github Actions OIDC identity pool provider for CI/CD" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.aud=assertion.aud" \
  --issuer-uri="https://token.actions.githubusercontent.com"

gcloud iam service-accounts add-iam-policy-binding \
        "my-service-account@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/deb-pool/attribute.repository/my-org/my-repo"


# Enable necessary APIs for GKE, Google Cloud Storage, and Dataproc
gcloud services enable container.googleapis.com \
    storage-component.googleapis.com \
    dataproc.googleapis.com