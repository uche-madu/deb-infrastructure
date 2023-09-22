
# DEB Infrastructure as Code Repository

## Project Steps: How to Run
## 1. Project Setup: Provision Google Cloud Resources

The following steps assume that a Google Cloud project has been created, Google Cloud SDK has been installed locally and configured to use the project.

* Run `gcloud auth application-default login` and follow the prompt.

* Make `setup.sh` executable: Run `chmod +x setup.sh`
* Create a service account with necessary roles by running `setup.sh`: `./setup.sh`

### Create ssh keys to set up Git-sync for Airflow DAGS
1. Run this to generate two files: `airflow_git_ssh_key` (private key) and `airflow_git_ssh_key.pub` (public key):
   ```
   ssh-keygen -t rsa -b 4096 -f ~/airflow-ssh-key
   ```

3. Set the public key on the Airflow DAGs repository:
    - Go to your GitHub repository.
    - Navigate to `Settings` > `Deploy keys`.
    - Click on `Add deploy key`.
    - Provide a title and paste the contents of `airflow_git_ssh_key.pub` into the Key field.
    - Check `allow write access`
    - Click `Add key`.

### Apply the config:
* Enter the terraform directory `cd terraform` 
* Run: 
    ```bash
    terraform init
    terraform plan
    terraform apply --auto-approve
    ```

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

  
