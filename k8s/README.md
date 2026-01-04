# Kubernetes Deployment Guide

This directory contains Kustomize-based Kubernetes manifests for deploying the PetClinic application to GKE.

## Structure

```
k8s/
├── base/                    # Base manifests (environment-agnostic)
│   ├── kustomization.yaml
│   ├── serviceaccount.yaml  # K8s SA for Workload Identity
│   ├── deployment.yaml      # App container + Cloud SQL Proxy sidecar
│   ├── service.yaml         # ClusterIP service
│   ├── gateway.yaml         # Gateway API - provisions GCP Load Balancer
│   └── httproute.yaml       # HTTP routing rules
└── overlays/                # Environment-specific configurations
    ├── test/
    │   └── kustomization.yaml
    └── prod/
        └── kustomization.yaml
```

## Prerequisites

1. **GKE cluster access** - Configure kubectl:
   ```bash
   # For test
   gcloud container clusters get-credentials gorillaclinic-k8s-gke-test \
     --region=europe-west1 \
     --project=tf-gcp-proj-test

   # For prod
   gcloud container clusters get-credentials gorillaclinic-k8s-gke-prod \
     --region=europe-west1 \
     --project=tf-gcp-proj-prod
   ```

2. **Database password secret** - Create from Secret Manager:
   ```bash
   # For test
   kubectl create secret generic db-password \
     --from-literal=password=$(gcloud secrets versions access latest \
       --secret=petclinic-db-password-test \
       --project=tf-gcp-proj-test)

   # For prod
   kubectl create secret generic db-password \
     --from-literal=password=$(gcloud secrets versions access latest \
       --secret=petclinic-db-password-prod \
       --project=tf-gcp-proj-prod)
   ```

3. **Workload Identity binding** - Already configured in Terraform:
   - GCP Service Account: `petclinic-app-{env}@{project}.iam.gserviceaccount.com`
   - K8s Service Account: `default/petclinic`
   - Binding: Allows K8s SA to impersonate GCP SA

## Deployment

### Deploy to Test
```bash
# Switch to test cluster context
gcloud container clusters get-credentials gorillaclinic-k8s-gke-test \
  --region=europe-west1 \
  --project=tf-gcp-proj-test

# Create database password secret
kubectl create secret generic db-password \
  --from-literal=password=$(gcloud secrets versions access latest \
    --secret=petclinic-db-password-test \
    --project=tf-gcp-proj-test)

# Apply manifests
kubectl apply -k overlays/test

# Watch deployment progress
kubectl rollout status deployment/petclinic
kubectl get gateway,httproute,pods
```

### Deploy to Prod
```bash
# Switch to prod cluster context
gcloud container clusters get-credentials gorillaclinic-k8s-gke-prod \
  --region=europe-west1 \
  --project=tf-gcp-proj-prod

# Create database password secret
kubectl create secret generic db-password \
  --from-literal=password=$(gcloud secrets versions access latest \
    --secret=petclinic-db-password-prod \
    --project=tf-gcp-proj-prod)

# Apply manifests
kubectl apply -k overlays/prod

# Watch deployment progress
kubectl rollout status deployment/petclinic
kubectl get gateway,httproute,pods
```

## Get Application URL

The Gateway API automatically provisions a Google Cloud Load Balancer with an external IP:

```bash
# Get the external IP (may take 2-5 minutes to provision)
kubectl get gateway petclinic-gateway -o jsonpath='{.status.addresses[0].value}'
```

Once you have the IP address, you can access the application via:
- Direct IP: `http://<EXTERNAL_IP>`
- With nip.io: `http://petclinic.<EXTERNAL_IP>.nip.io`

## Architecture Details

### Workload Identity Flow
1. Pod uses K8s ServiceAccount `default/petclinic`
2. K8s SA has annotation pointing to GCP SA
3. Terraform created IAM binding allowing impersonation
4. Cloud SQL Proxy uses this identity to connect to database

### Cloud SQL Connection
- Cloud SQL Proxy runs as sidecar container
- Listens on localhost:5432
- Application connects to `jdbc:postgresql://localhost:5432/petclinic`
- Proxy handles authentication via Workload Identity

### Load Balancer
- Gateway API provisions GCP HTTP(S) Load Balancer
- Class: `gke-l7-global-external-managed`
- External IP assigned automatically
- Health checks configured from readiness probe

### Environment Differences
**Test:**
- 2 replicas
- db-f1-micro database (shared core)
- Service Account: petclinic-app-test@tf-gcp-proj-test.iam.gserviceaccount.com

**Prod:**
- 3 replicas
- db-custom-2-7680 database (2 vCPU, 7.5 GB RAM)
- Service Account: petclinic-app-prod@tf-gcp-proj-prod.iam.gserviceaccount.com

## Troubleshooting

### Check pod status
```bash
kubectl get pods -l app=petclinic
kubectl describe pod <pod-name>
kubectl logs <pod-name> -c petclinic
kubectl logs <pod-name> -c cloud-sql-proxy
```

### Check Workload Identity
```bash
# Verify annotation on K8s SA
kubectl get serviceaccount petclinic -o yaml

# Test from inside pod
kubectl run -it --rm debug --image=google/cloud-sdk:slim --serviceaccount=petclinic -- gcloud auth list
```

### Check Gateway status
```bash
kubectl describe gateway petclinic-gateway
kubectl describe httproute petclinic-route
```

### Check database connectivity
```bash
# Exec into pod
kubectl exec -it <pod-name> -c petclinic -- /bin/sh

# Inside pod, check if proxy is listening
netstat -tlnp | grep 5432

# Check if database is accessible
apt-get update && apt-get install -y postgresql-client
psql -h localhost -U petclinic -d petclinic -c "SELECT version();"
```

## Updating

### Update application image
```bash
# Build and push new image
docker build -t europe-west1-docker.pkg.dev/tf-gcp-proj-main/petclinic-images/petclinic:v1.2.3 .
docker push europe-west1-docker.pkg.dev/tf-gcp-proj-main/petclinic-images/petclinic:v1.2.3

# Update image in base/deployment.yaml or use kustomize image transformer
kubectl set image deployment/petclinic \
  petclinic=europe-west1-docker.pkg.dev/tf-gcp-proj-main/petclinic-images/petclinic:v1.2.3

# Or reapply with updated manifests
kubectl apply -k overlays/test
```

### Rolling restart
```bash
kubectl rollout restart deployment/petclinic
kubectl rollout status deployment/petclinic
```

## Cleanup

```bash
kubectl delete -k overlays/test
# or
kubectl delete -k overlays/prod
```

Note: This deletes the Gateway which also deletes the GCP Load Balancer.
