# GitHub Actions Workflows

This directory contains CI/CD workflows for the PetClinic application.

## Workflows

### Deploy Application (`deploy-application.yml`)

**Trigger:** Manual only (workflow_dispatch)

**Purpose:** Deploy application to test or prod environment with full control over when and what to deploy.

**Inputs:**
- `environment` (required): Choose `test` or `prod`
- `image_tag` (optional): Specific Docker image tag to deploy (defaults to git SHA)

**What it does:**
1. Builds Docker image with specified tag (or git SHA)
2. Pushes to Artifact Registry
3. Tags image as `latest`
4. Deploys to selected GKE cluster using Kustomize
5. Creates/updates database password secret from Secret Manager
6. Waits for rollout to complete
7. Performs health check
8. Displays deployment status and application URL

**How to use:**
1. Go to Actions tab in GitHub
2. Select "Deploy Application to GKE" workflow
3. Click "Run workflow"
4. Choose environment (test or prod)
5. Optionally specify an image tag
6. Click "Run workflow"

**Example scenarios:**
- Deploy latest code to test: Run with `environment=test`, leave `image_tag` empty
- Deploy latest code to prod: Run with `environment=prod`, leave `image_tag` empty
- Deploy specific version to prod: Run with `environment=prod`, `image_tag=abc123`
- Rollback: Run with `environment=prod`, `image_tag=<previous-working-sha>`

### Deploy to Cloud Run (`deploy-cloud-run.yml`) - DEPRECATED

**Status:** Non-functional after OIDC migration (2026-01-04)

**Reason:** This workflow relied on the `TERRAFORM_GCP_SA_KEY` secret which has been removed for security reasons. The project has migrated to GKE, making Cloud Run deployment legacy infrastructure.

**Note:** This file is kept for reference only. For current deployments, use the GKE workflow above.

## Secrets Required

The workflows require the following GitHub secrets:

### `WIF_PROVIDER`
- **Description:** Workload Identity Federation provider resource name
- **Used for:** Authenticating GitHub Actions to Google Cloud via OIDC
- **Format:** `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions/providers/github-provider`
- **Setup:** Created during Workload Identity Federation configuration

### `WIF_SERVICE_ACCOUNT`
- **Description:** GCP service account email for CI/CD operations
- **Value:** `terraform-sa@tf-gcp-proj-main.iam.gserviceaccount.com`
- **Used for:**
  - Authenticating to Google Cloud
  - Pushing Docker images to Artifact Registry
  - Accessing Secret Manager
  - Configuring kubectl for GKE clusters
- **Permissions:** Owner role on all three projects (main, test, prod)

### ~~`TERRAFORM_GCP_SA_KEY`~~ (DEPRECATED - Removed 2026-01-04)
- **Status:** Replaced with OIDC authentication via Workload Identity Federation
- **Migration:** Service account key removed from GitHub secrets for improved security
- **See:** `WORKLOAD_IDENTITY_FEDERATION.md` for details on the new authentication method

## GitHub Environments (Optional)

For additional protection on prod deployments, you can configure GitHub Environments:

1. Go to Settings → Environments → New environment
2. Create `test` and `prod` environments
3. For `prod`, add protection rules:
   - Required reviewers: Add team members who must approve prod deployments
   - Wait timer: Optional delay before deployment
   - Deployment branches: Restrict to `main` branch only

The `deploy-application.yml` workflow already references these environments and will enforce protection rules if configured.

## Architecture

### Application Deployment Pipeline
```
Code Push → Build Image → Push to Registry → Deploy to GKE → Health Check
```

**Stack:**
- Docker image: Built from Dockerfile, contains Spring Boot app
- Artifact Registry: Stores container images (shared across environments)
- GKE Autopilot: Runs containers with auto-scaling
- Cloud SQL: PostgreSQL database (private IP only)
- Cloud SQL Proxy: Sidecar for secure database access
- Gateway API: Provisions Google Cloud Load Balancer
- Workload Identity: Secure authentication without keys

### Separation of Concerns

**Infrastructure Pipeline** (Terraform - separate workflow, to be created):
- Manages GKE clusters, Cloud SQL, VPCs, IAM bindings
- Deployed via Terraform with state in GCS
- Changes require careful review

**Application Pipeline** (This directory):
- Manages application code, Docker images, K8s deployments
- Can be run frequently for application updates
- Independent of infrastructure changes

### Environment Configuration

Both environments use Kustomize overlays to customize deployments:

**Base** (`k8s/base/`):
- Common configuration shared by all environments
- ServiceAccount, Deployment, Service, Gateway, HTTPRoute

**Test** (`k8s/overlays/test/`):
- Project: `tf-gcp-proj-test`
- Cluster: `gorillaclinic-k8s-gke-test`
- Replicas: 2
- Database: `petclinic-db-test` (ZONAL, db-f1-micro)
- Service Account: `petclinic-app-test@tf-gcp-proj-test.iam.gserviceaccount.com`

**Prod** (`k8s/overlays/prod/`):
- Project: `tf-gcp-proj-prod`
- Cluster: `gorillaclinic-k8s-gke-prod`
- Replicas: 3
- Database: `petclinic-db-prod` (REGIONAL, db-custom-2-7680)
- Service Account: `petclinic-app-prod@tf-gcp-proj-prod.iam.gserviceaccount.com`

## Monitoring Deployments

### Check deployment status
```bash
# For test
gcloud container clusters get-credentials gorillaclinic-k8s-gke-test \
  --region=europe-west1 --project=tf-gcp-proj-test
kubectl get pods -l app=petclinic
kubectl get gateway petclinic-gateway

# For prod
gcloud container clusters get-credentials gorillaclinic-k8s-gke-prod \
  --region=europe-west1 --project=tf-gcp-proj-prod
kubectl get pods -l app=petclinic
kubectl get gateway petclinic-gateway
```

### View application logs
```bash
kubectl logs -l app=petclinic -c petclinic --tail=100 -f
```

### Check Cloud SQL Proxy logs
```bash
kubectl logs -l app=petclinic -c cloud-sql-proxy --tail=100
```

## Troubleshooting

### Image pull failures
- Verify Artifact Registry IAM permissions in `terraform/stacks/env/artifact-registry-access.tf`
- Check that image exists: `gcloud artifacts docker images list europe-west1-docker.pkg.dev/tf-gcp-proj-main/petclinic-images`

### Database connection failures
- Verify Cloud SQL Proxy is using `--private-ip` flag
- Check Workload Identity binding exists in Terraform
- Verify GCP service account has `roles/cloudsql.client`

### Gateway not getting IP
- Check Gateway status: `kubectl describe gateway petclinic-gateway`
- Gateway provisioning can take 2-5 minutes
- Verify HTTPRoute is attached: `kubectl get httproute`

### Health check failures
- Check pod logs for application errors
- Verify readiness probe endpoint: `kubectl get pods -o yaml | grep readinessProbe -A 5`
- Test application directly: `kubectl port-forward deployment/petclinic 8080:8080`

## Future Improvements

1. **Add build caching** - Use Docker layer caching or kaniko for faster builds
2. **Add integration tests** - Run tests before deployment
3. ~~**Workload Identity Federation** - Remove service account key, use OIDC instead~~ ✅ **COMPLETED (2026-01-04)**
4. **Blue/green deployments** - Use Argo Rollouts for zero-downtime deployments
5. **Canary deployments** - Gradually roll out to subset of users
6. **Rollback automation** - Auto-rollback on health check failure
7. **Slack notifications** - Notify team of deployments and failures
8. **Kubernetes API OIDC** - Configure GKE to use OIDC for kubectl access (separate from CI/CD OIDC)
