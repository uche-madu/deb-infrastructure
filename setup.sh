#!/bin/bash

echo "Running setup to create a GCS bucket to be used as the remote backend for terraform state, service account with necessary roles, and setup workflow identity federation and secrets..."

# Retrieve the project ID
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $(gcloud config get-value core/project) --format=value\(projectNumber\))
USER_EMAIL="example@gmail.com" # REPLACE
ATTRIBUTE_NAME="repository_owner_id" # REPLACE OR USE AS IS
ATTRIBUTE_VALUE="27293138" # REPLACE


export BUCKET_NAME="gs://deb-capstone"
# Check and create the GCS bucket with uniform access control if it doesn't exist
gsutil ls $BUCKET_NAME &> /dev/null || gsutil mb -l us -b on $BUCKET_NAME

# Copy project csv files into separate cloud storage folders idempotently
gsutil rsync -r data/log_reviews $BUCKET_NAME/project-data/log_reviews
gsutil rsync -r data/movie_reviews $BUCKET_NAME/project-data/movie_reviews
gsutil rsync -r data/user_purchases $BUCKET_NAME/project-data/user_purchases


# Copy dataproc initialization actions to our bucket if they are not there already
REGION="us-central1"

# Define the initialization actions and their destination paths
declare -A INIT_ACTIONS=(
    ["python/pip-install.sh"]="${BUCKET_NAME}/dataproc-initialization-actions/python/v1.0/pip-install.sh"
    ["connectors/connectors.sh"]="${BUCKET_NAME}/dataproc-initialization-actions/connectors/v1.0/connectors.sh"
)

# Iterate over the initialization actions and copy them if they don't exist in the bucket
for INIT_ACTION in "${!INIT_ACTIONS[@]}"; do
    DEST_PATH="${INIT_ACTIONS[$INIT_ACTION]}"
    # Check if the file already exists in the bucket
    if ! gsutil -q stat ${DEST_PATH}; then
        # If not, copy the initialization action to the bucket
        gsutil cp gs://goog-dataproc-initialization-actions-${REGION}/${INIT_ACTION} ${DEST_PATH}
        echo "Initialization action ${INIT_ACTION} copied to ${DEST_PATH}"
    else
        echo "Initialization action ${INIT_ACTION} already exists in ${DEST_PATH}"
    fi
done

# Create a Service Account
SERVICE_ACCOUNT_NAME="deb-sa"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Check if the service account already exists
EXISTING_SA=$(gcloud iam service-accounts list --filter="email:${SERVICE_ACCOUNT_EMAIL}" --format="get(email)" --project="${PROJECT_ID}")

# Create the service account if it doesn't exist
if [ -z "$EXISTING_SA" ]; then
  echo "Creating service account ${SERVICE_ACCOUNT_NAME}..."
  gcloud iam service-accounts create "${SERVICE_ACCOUNT_NAME}" \
      --display-name="DEB SA" \
      --description="Service Account for Wizeline Data Engineering Bootcamp" \
      --project="${PROJECT_ID}"
else
  echo "Service account ${SERVICE_ACCOUNT_NAME} already exists."
fi


# Project-level roles
PROJECT_ROLES=(
  "roles/container.admin"
  "roles/storage.admin"
  "roles/dataproc.editor"
  "roles/storage.objectViewer"
  "roles/iam.serviceAccountTokenCreator"
  "roles/serviceusage.serviceUsageConsumer"
  "roles/compute.networkAdmin"
  "roles/iam.serviceAccountAdmin"
  "roles/serviceusage.serviceUsageAdmin"
  "roles/iam.serviceAccountUser"
  "roles/iam.securityAdmin"
  "roles/secretmanager.admin"
  "roles/cloudsql.admin"
  "roles/artifactregistry.admin"
  "roles/bigquery.dataEditor"
)

# Service account-level roles
SA_ROLES=(
  "roles/iam.serviceAccountTokenCreator"
  "roles/iam.workloadIdentityUser"
)

# Function to check and add project-level roles
check_and_add_project_role() {
  local project_id=$1
  local member=$2
  local role=$3

  existing_roles=$(gcloud projects get-iam-policy $project_id --flatten="bindings[].members" --format="table(bindings.role,bindings.members)" --filter="bindings.members:$member")

  if echo "$existing_roles" | grep -q "$role"; then
    echo "Project role $role is already assigned to $member."
  else
    gcloud projects add-iam-policy-binding $project_id --member="$member" --role="$role"
  fi
}

# Function to check and add service account-level roles
check_and_add_sa_role() {
  local sa_email=$1
  local member=$2
  local role=$3

  existing_roles=$(gcloud iam service-accounts get-iam-policy $sa_email --flatten="bindings[].members" --format="table(bindings.role,bindings.members)" --filter="bindings.members:$member")

  if echo "$existing_roles" | grep -q "$role"; then
    echo "Service account role $role is already assigned to $member."
  else
    gcloud iam service-accounts add-iam-policy-binding $sa_email --member="$member" --role="$role"
  fi
}

# Check and add project-level roles
for role in "${PROJECT_ROLES[@]}"; do
  check_and_add_project_role $PROJECT_ID "serviceAccount:$SERVICE_ACCOUNT_EMAIL" $role
done

# Check and add service account-level roles
# Define an array of member types
MEMBER_TYPES=(
  "user:$USER_EMAIL" 
  "principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/deb-pool/attribute.${ATTRIBUTE_NAME}/${ATTRIBUTE_VALUE}")

# Loop through each role and each member type, and assign the role to the service account
for role in "${SA_ROLES[@]}"; do
  for member in "${MEMBER_TYPES[@]}"; do
    check_and_add_sa_role $SERVICE_ACCOUNT_EMAIL $member $role
  done
done

# Function to check and create Workload Identity Pool
check_and_create_wipool() {
  local pool_name=$1

  existing_pools=$(gcloud iam workload-identity-pools list --location=global --format="value(name)")

  if echo "$existing_pools" | grep -q "$pool_name"; then
    echo "Workload Identity Pool $pool_name already exists."
  else
    gcloud iam workload-identity-pools create "$pool_name" \
      --location="global" \
      --display-name="Wizeline DEB pool" \
      --description="Wizeline DEB pool"
  fi
}

# Function to check and create OIDC provider
check_and_create_oidc_provider() {
  local pool_name=$1
  local provider_name=$2

  existing_providers=$(gcloud iam workload-identity-pools providers list --workload-identity-pool=$pool_name --location=global --format="value(name)")

  if echo "$existing_providers" | grep -q "$provider_name"; then
    echo "OIDC provider $provider_name already exists in pool $pool_name."
  else
    gcloud iam workload-identity-pools providers create-oidc "$provider_name" \
      --location="global" \
      --workload-identity-pool="$pool_name" \
      --display-name="Github Actions" \
      --description="Github Actions OIDC identity pool provider for CI/CD" \
      --attribute-mapping="google.subject=assertion.sub,attribute.repository_owner_id=assertion.repository_owner_id,attribute.repository=assertion.repository,attribute.actor=assertion.actor" \
      --issuer-uri="https://token.actions.githubusercontent.com"
  fi
}

# Check and create Workload Identity Pool
check_and_create_wipool "deb-pool"

# Check and create OIDC provider
check_and_create_oidc_provider "deb-pool" "github-actions"


# Create Google Secrets from the private keys in your local terminal
# Function to create a Google Cloud secret if it does not already exist
create_secret() {
    local secret_name=$1
    local file_path=$2

    # Check if the secret exists
    gcloud secrets describe "$secret_name" &> /dev/null

    # Check the exit status of the last command
    if [ $? -ne 0 ]; then
        echo "Secret $secret_name does not exist. Creating..."
        gcloud secrets create "$secret_name" \
            --replication-policy="automatic" \
            --data-file="$file_path"
    else
        echo "Secret $secret_name already exists. Skipping creation."
    fi
}

# Usage of the create_secret function
create_secret "airflow_ssh_key_private" "$HOME/airflow-ssh-key"
create_secret "argocd_ssh_key_private" "$HOME/argocd_ssh_key"

echo "Setup complete!"
