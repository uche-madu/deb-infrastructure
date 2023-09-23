
# DEB Infrastructure as Code Repository
![Terraform Workflow](https://github.com/uche-madu/deb-infrastructure/actions/workflows/apply.yaml/badge.svg)

## Project Setup: Provision Google Cloud Resources

The following steps assume that a Google Cloud project has been created, Google Cloud SDK has been installed locally and configured to use the project.

* Run this and follow the prompt:
    ```
    gcloud auth application-default login
    ``` 

* Make `setup.sh` executable: 
    ```
    chmod +x setup.sh
    ```
* The `setup.sh` script creates a GCS bucket to be used as the remote backend for terraform state, service account with necessary roles, and setup workflow identity federation. 
    
    *Run the script manually from your local terminal for the initial setup to create foundational resources. Once these resources are in place, you can manage the rest of your infrastructure as code using Terraform and GitHub Actions. The script is programmed to be idempotent i.e. it checks if any of the resources already exists and skips creation if so. Therefore, an additional resource can be created using the script without having to worry about errors or duplication of cloud resources. For instance, a new role can be assigned to the service account by adding the role to the `PROJECT_ROLES` or `SA_ROLES` array.*

`Note:` To configure workload identity federation in `setup.sh`, use GitHub's REST API to obtain unique values such as the repository_id or repository_owner_id to reduce the chances of [cybersquatting and typosquatting attacks](https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines#:~:text=Caution%3A%20There,your%20GitHub%20organization.). To do this, run this command and enter your Github password at the prompt: 

```
curl -u "your-github-username" https://api.github.com/repos/your-github-username/your-repo-name
```
For example:
    ```
    curl -u "uche-madu" https://api.github.com/repos/uche-madu/deb-infrastructure
    ```
In `setup.sh`, replace the USER_EMAIL, ATTRIBUTE_NAME, ATTRIBUTE_VALUE placeholders in this code:

```bash
USER_EMAIL="example@gmail.com" # Replace with your GCP user account email
ATTRIBUTE_NAME="your-attribute-name"
ATTRIBUTE_VALUE="your-attribute-value"
```
For example, if using repository_owner_id, it should look like this:
```bash
ATTRIBUTE_NAME="repository_owner_id"
ATTRIBUTE_VALUE="29379237"
```
Finally, execute the script:
```
./setup.sh
```

## Create ssh keys to set up Git-sync for Airflow DAGS
1. Run this to generate two files: `airflow_git_ssh_key` (private key) and `airflow_git_ssh_key.pub` (public key):
   ```
   ssh-keygen -t rsa -b 4096 -f ~/airflow_git_ssh_key
   ```

2. Set the public key on the Airflow DAGs repository:
    - Go to your GitHub repository.
    - Navigate to `Settings` > `Deploy keys`.
    - Click on `Add deploy key`.
    - Provide a title and paste the contents of `airflow_git_ssh_key.pub` into the Key field.
    - Check `allow write access`
    - Click `Add key`.

3. Set Up GitHub Secrets with the private key
    - Go to your GitHub repository and click on the `Settings` tab.
    - In the left sidebar, click on `Secrets`.
    - Click on `New repository secret` and add your secret. Name it `AIRFLOW_SSH_KEY_PRIVATE` (matching the variable name used in variables.tf and gcloud-secrets.tf, and the Github Actions workflow) and paste the content of your airflow_git_ssh_key file into the value field.
    - Save

4. (Optional) This project is designed to be run via CI/CD. But if running terraform via the local terminal, you'd could create an environment variable to pass the private key to `terraform plan` and `terraform apply`:
    ```
    export TF_VAR_AIRFLOW_SSH_KEY_PRIVATE="$(cat ~/airflow_git_ssh_key)"
    ```

## Apply the Config
The terraform config is to be applied via Github Actions, manually or on `pull request` to the `main` branch. Branch protection has been setup for the `main` branch to require that `commits` can only be made to a `feature` branch for `review` and pass `status checks` before being merged with the `main` branch through a `pull request`.

    ```bash
    # Create a new branch
    git checkout -b feature/my-new-feature

    # Make your changes and commit them
    git add .
    git commit -m "add my new feature"

    # Push the branch to GitHub
    git push origin feature/my-new-feature
    ```
    * However, For local only deployment, enter the terraform directory `cd terraform` and run: 
        ```bash
        terraform init
        terraform fmt
        terraform validate
        terraform plan
        terraform apply --auto-approve
        ```
    `Note:` This assumes that `TF_VAR_AIRFLOW_SSH_KEY_PRIVATE` has already been set as described above.
    
### Get Cluster Credentials
* Fetch credentials for the running cluster. It updates a kubeconfig file (written to `HOME/.kube/config`) with appropriate credentials and endpoint information to point `kubectl` at the cluster.

    `Note:` Use the `-raw` flag to eliminate quotes from `terraform output`:
    
    ```
     gcloud container clusters get-credentials $(terraform output -raw gke_cluster_name) --location=$(terraform output -raw gke_cluster_location)
     ```

* Run this command to retrieve the load balancer external IP address and port from the airflow namespace.
    ```
     kubectl get service/airflow-webserver -n airflow
    ```
  The output would look similar to this:

    ```bash
    NAME                TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)          AGE
    airflow-webserver   LoadBalancer   10.10.21.86   34.41.35.207   8080:32182/TCP   60m
    ```
* Paste the external-ip:port (in this case: `34.41.35.207:8080`) in your browser then login to Airflow with the default `username` and `password` (`admin` and `admin`)

***With that, the infrastructure setup is complete. The rest of the project will be completed from the [DEB Application repository](https://github.com/uche-madu/deb-application).***

  
