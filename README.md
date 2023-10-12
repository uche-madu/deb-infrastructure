
# 🗜️⚙️ DEB Infrastructure-as-Code Repository 🔩🧰
![Terraform Workflow](https://github.com/uche-madu/deb-infrastructure/actions/workflows/apply.yaml/badge.svg)

***This is one of two repositories with code for the entire DEB Project. While this repository focuses on provisioning cloud resources, the [DEB Application repository](https://github.com/uche-madu/deb-application) focuses on the application code such as Airflow DAGs. This separation of concerns via separate repositories aims to follow GitOps Principles.***

## Project Setup: Provision Google Cloud Resources

The following steps assume that a Google Cloud project has been created, Google Cloud SDK has been installed locally and configured to use the project.

Run this and follow the prompt:    
  ```
  gcloud auth application-default login
  ``` 

### Configure and Execute Setup Script 🛠️⚙️
The `setup.sh` script creates a GCS bucket to be used as the remote backend for terraform state, service account with necessary roles, and setup workflow identity federation. 
Make `setup.sh` executable:

  ```
  chmod +x setup.sh
  ```
    
> *Run the script manually from your local terminal for the initial setup to create foundational resources. Once these resources are in place, you can manage the rest of your infrastructure as code using Terraform and GitHub Actions. The script is programmed to be idempotent i.e. it checks if any of the resources already exists and skips creation if so. Therefore, an additional resource can be created using the script without having to worry about errors or duplication of cloud resources. For instance, a new role can be assigned to the service account by adding the role to the `PROJECT_ROLES` or `SA_ROLES` array.*

> [!IMPORTANT]
> To configure workload identity federation in `setup.sh`, use GitHub's REST API to obtain unique values such as the repository_id or repository_owner_id to reduce the chances of [cybersquatting and typosquatting attacks](https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines#:~:text=Caution%3A%20There,your%20GitHub%20organization.). To do this, run this command and enter your Github password at the prompt: 

  ```
  curl -u "your-github-username" https://api.github.com/repos/your-github-username/your-repo-name
  ```
For example:
  ```
  curl -u "uche-madu" https://api.github.com/repos/uche-madu/deb-infrastructure
  ```

In `setup.sh`, replace the `USER_EMAIL`, `ATTRIBUTE_NAME`, `ATTRIBUTE_VALUE` placeholders:

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

## Create SSH Keys to Set Up Git-Sync for Airflow DAGs
1. Run this to generate two files: `airflow-ssh-key` (private key) and `airflow-ssh-key.pub` (public key):
   ```
   ssh-keygen -t rsa -b 4096 -f ~/airflow-ssh-key
   ```

2. Set the public key on the Airflow DAGs repository:
    - Go to your application GitHub repository i.e. the repository that contains airflow DAGs, not the one that contains terraform code.
    - Navigate to `Settings` > `Deploy keys`.
    - Click on `Add deploy key`.
    - Provide a title and paste the contents of `airflow-ssh-key.pub` into the Key field. You can access the content of `airflow-ssh-key.pub` by running:
      ```
      cat ~/airflow_git_ssh_key.pub
      ```
    - Check `allow write access`
    - Click `Add key`.

3. Create Google Cloud Secret with the private key
    - The `setup.sh` script handles this part

## Create SSH Keys to Set Up ArgoCD Repo Connection
1. Similarly, run this to generate two files: `argocd_ssh_key` (private key) and `argocd_ssh_key.pub` (public key):
   ```
   ssh-keygen -t rsa -b 4096 -f ~/argocd_ssh_key
   ```

2. Set the public key on the Infrastructure repository:
    - Go to your infrastrucute GitHub repository i.e. the repository that contains that contains terraform code equivalent to this one.
    - Navigate to `Settings` > `Deploy keys`.
    - Click on `Add deploy key`.
    - Provide a title and paste the contents of `argocd_ssh_key.pub` into the Key field. You can access the content of `argocd_ssh_key.pub` by running:
      ```
      cat ~/argocd_ssh_key.pub
      ```
    - Check `allow write access`
    - Click `Add key`.

3. Create Google Cloud Secret with the private key
    - The `setup.sh` script handles this part


## Apply the Config
The terraform config is to be applied via Github Actions, manually via `workflow_dispatch` or on `pull_request` to the `main` branch. Branch protection has been setup for the `main` branch to require that `commits` can only be made to a `feature` branch for `review` and pass `status checks` before being merged with the `main` branch through a `pull_request`.

```bash
# Create a new branch
git checkout -b feature/my-new-feature

# Make your changes and commit them
git add .
git commit -m "add my new feature"

# Push the branch to GitHub
git push origin feature/my-new-feature
```
However, For local only deployment, enter the terraform directory `cd terraform` and run: 
```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply -auto-approve
```

To delete resources run:
```bash
terraform destroy -auto-approve
```

    
### Get Cluster Credentials
* Fetch credentials for the running cluster. It updates a kubeconfig file (written to `HOME/.kube/config`) with appropriate credentials and endpoint information to point `kubectl` at the cluster.

    > [!NOTE]
    >  Use the `-raw` flag to eliminate quotes from `terraform output`:
    
    ```
    gcloud container clusters get-credentials $(terraform output -raw gke_cluster_name) --location=$(terraform output -raw gke_cluster_location)
    ```

### Build the Custom Airflow Image
Now that the required cloud resources are up and running, thanks to Terraform, it's time to trigger the build and push of the custom Airflow image from the [DEB Application repository](https://github.com/uche-madu/deb-application). Clone that repository and follow the instructions in the README.md to setup your application repo and build the image. Once that is complete, move on to login to the ArgoCD UI as described next.

### Login to the ArgoCD UI
* Obtain the initial `admin` password
  ```
  kubectl -n argocd get secret argocd-initial-admin-secret -o json | jq .data.password -r | base64 -d; echo
  ```
* From the from the navigation menu of the Google Cloud Console > `Kubernetes Engine` > `Services & Ingress` click the argocd-server endpoint. E.g. https://34.41.120.156:80
* Create a new ArgoCD App of Apps Application with the manifest in `argocd-app/multi-app/master-app.yml`. This triggers the creation of Airflow from the helm chart.

### Login to the Airflow UI
* Run this command to retrieve the load balancer external IP address and port from the airflow namespace.
    ```
    kubectl get service/airflow-webserver -n airflow
    ```
  The output would look similar to this:

    ```bash
    NAME                TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
    airflow-webserver   LoadBalancer   10.10.21.123   34.42.45.72   8080:31560/TCP   42m
    ```
* Paste the external-ip:port (in this case: `34.42.45.72:8080`) in your browser then login to Airflow with the default `username` and `password` (`admin` and `admin`)
* Alternatively, from the navigation menu of the Google Cloud Console > `Kubernetes Engine` > `Services & Ingress` click the airflow-webserver endpoint:
  
![gke-services](https://github.com/uche-madu/deb-infrastructure/assets/29081638/5899471a-fc80-4a69-bdbb-1cd9d97f0ba4)

***👍 With that, the infrastructure setup is complete. The rest of the project will be completed from the [DEB Application repository](https://github.com/uche-madu/deb-application).***


## 💲🧽💻 Cleaning Up Resources 💻🧼💲
- ⚠️ To destroy the infrastructure at any time, utilize the workflow_dispatch trigger from the Actions page. You might have to trigger the workflow multiple times to destroy it all.
- ⚠️ The persistent volume claim for the Airflow Triggerer does not get deleted by the workflow. Do that manually from the Google Cloud console.

### Debugging Terraform

1. As in the screenshot below, if you get the `Error: Error acquiring the state lock` while running terraform, which could happen when two workflows runs run at the same time trying to access the terraform state at the same time, run the following command:

![terraform-state-lock](https://github.com/uche-madu/deb-infrastructure/assets/29081638/a36d410c-cde0-41ca-8423-fc9d60fe05a3)


```
terraform force-unlock -force LOCK_ID
```
For example:
```
terraform force-unlock -force 1695529512488132
```

2. Terraform destroy might fail due to the kubernetes_namespace.argocd resource being stuck in a terminating stage. Here's how to get it unstuck from your terminal and complete terraform destroy. I have provided a script to run force-delete a namespace. Note that the script runs `kubectl` commands in the background so it requires that cluster credentials are set in the terminal as usual. To force-delete argocd namespace run:
    ```
    ./del_ns.sh argocd
    ``` 
Then trigger terraform destroy again to complete the destruction of all resources.

- To investigate the problem manually, you follow these steps: 
  - Find out details about the stuck argocd namespace:
    ```
    kubectl describe ns argocd
    ```
    The output would be similar to this:
    ```
    Name:         argocd
    Labels:       kubernetes.io/metadata.name=argocd
    Annotations:  <none>
    Status:       Terminating
    Conditions:
      Type                                         Status  LastTransitionTime               Reason                Message
      ----                                         ------  ------------------               ------                -------
      NamespaceDeletionDiscoveryFailure            False   Sat, 30 Sep 2023 19:50:26 +0100  ResourcesDiscovered   All resources successfully discovered
      NamespaceDeletionGroupVersionParsingFailure  False   Sat, 30 Sep 2023 19:50:26 +0100  ParsedGroupVersions   All legacy kube types successfully parsed
      NamespaceDeletionContentFailure              False   Sat, 30 Sep 2023 19:50:26 +0100  ContentDeleted        All content successfully deleted, may be waiting on finalization
      NamespaceContentRemaining                    True    Sat, 30 Sep 2023 19:50:26 +0100  SomeResourcesRemain   Some resources are remaining: applications.argoproj.io has 1 resource instances
      NamespaceFinalizersRemaining                 True    Sat, 30 Sep 2023 19:50:26 +0100  SomeFinalizersRemain  Some content in the namespace has finalizers remaining: resources-finalizer.argocd.argoproj.io/foreground in 1 resource instances

    No resource quota.

    No LimitRange resource.
    ```
  - Notice the message: `applications.argoproj.io has 1 resource instances
      NamespaceFinalizersRemaining`
  - Edit the resource to remove all finalizers, in the above case, the line with `resources-finalizer.argocd.argoproj.io/foreground`:
    ```
    kubectl edit applications.argoproj.io -n argocd
    ```
  - Trigger terraform destroy again from the Github Actions workflow. Success! Hopefully.