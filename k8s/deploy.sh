#!/usr/bin/env bash
set -euo pipefail

# PetClinic GKE Deployment Helper Script
# Usage: ./k8s/deploy.sh <test|prod>

ENVIRONMENT="${1:-}"

if [[ "$ENVIRONMENT" != "test" && "$ENVIRONMENT" != "prod" ]]; then
    echo "Usage: $0 <test|prod>"
    exit 1
fi

echo "==> Deploying to $ENVIRONMENT environment"

# Set project and cluster based on environment
if [[ "$ENVIRONMENT" == "test" ]]; then
    PROJECT="tf-gcp-proj-test"
    CLUSTER="gorillaclinic-k8s-gke-test"
    DB_SECRET="petclinic-db-password-test"
else
    PROJECT="tf-gcp-proj-prod"
    CLUSTER="gorillaclinic-k8s-gke-prod"
    DB_SECRET="petclinic-db-password-prod"
fi

echo "==> Configuring kubectl for cluster $CLUSTER"
gcloud container clusters get-credentials "$CLUSTER" \
    --region=europe-west1 \
    --project="$PROJECT"

echo "==> Creating database password secret"
# Check if secret already exists
if kubectl get secret db-password &>/dev/null; then
    echo "    Secret db-password already exists, deleting..."
    kubectl delete secret db-password
fi

kubectl create secret generic db-password \
    --from-literal=password="$(gcloud secrets versions access latest \
        --secret="$DB_SECRET" \
        --project="$PROJECT")"

echo "==> Applying Kubernetes manifests"
kubectl apply -k "k8s/overlays/$ENVIRONMENT"

echo "==> Waiting for deployment to be ready"
kubectl rollout status deployment/petclinic --timeout=5m

echo "==> Deployment status"
kubectl get pods -l app=petclinic
kubectl get gateway,httproute,service

echo ""
echo "==> Getting Gateway external IP (may take a few minutes to provision)"
for i in {1..30}; do
    EXTERNAL_IP=$(kubectl get gateway petclinic-gateway -o jsonpath='{.status.addresses[0].value}' 2>/dev/null || echo "")
    if [[ -n "$EXTERNAL_IP" ]]; then
        echo "    External IP: $EXTERNAL_IP"
        echo "    URL: http://$EXTERNAL_IP"
        echo "    With nip.io: http://petclinic.$EXTERNAL_IP.nip.io"
        break
    fi
    if [[ $i -eq 30 ]]; then
        echo "    IP not assigned yet. Check manually with:"
        echo "    kubectl get gateway petclinic-gateway"
    else
        echo "    Waiting for IP assignment... ($i/30)"
        sleep 10
    fi
done

echo ""
echo "==> Deployment complete!"
