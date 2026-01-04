#!/bin/bash
# Setup Workload Identity Federation for GitHub Actions
# This script configures OIDC authentication to replace JSON service account keys
#
# Prerequisites:
# - gcloud CLI authenticated with sufficient permissions
# - Access to tf-gcp-proj-main project

set -e  # Exit on error

# Configuration
PROJECT_ID="tf-gcp-proj-main"
REPO_OWNER="gitmpr"  # TODO: Verify this is correct
REPO_NAME="private_repo_spring-petclinic"
SA_EMAIL="terraform-sa@tf-gcp-proj-main.iam.gserviceaccount.com"

echo "=========================================="
echo "Workload Identity Federation Setup"
echo "=========================================="
echo ""
echo "Project: ${PROJECT_ID}"
echo "Repository: ${REPO_OWNER}/${REPO_NAME}"
echo "Service Account: ${SA_EMAIL}"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

# Step 1: Create Workload Identity Pool
echo ""
echo "[Step 1/4] Creating Workload Identity Pool..."
echo "→ gcloud iam workload-identity-pools create github-actions --project=${PROJECT_ID} --location=global"
gcloud iam workload-identity-pools create "github-actions" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="GitHub Actions Pool" \
  --description="OIDC authentication for GitHub Actions"

echo "✓ Workload Identity Pool created"

# Step 2: Create Workload Identity Provider
echo ""
echo "[Step 2/4] Creating GitHub OIDC Provider..."
echo "→ gcloud iam workload-identity-pools providers create-oidc github-provider --workload-identity-pool=github-actions"
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github-actions" \
  --display-name="GitHub OIDC" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner == '${REPO_OWNER}'" \
  --issuer-uri="https://token.actions.githubusercontent.com"

echo "✓ GitHub OIDC Provider created"

# Step 3: Grant IAM Binding
echo ""
echo "[Step 3/4] Granting Workload Identity User role..."
echo "→ gcloud projects describe ${PROJECT_ID} (getting project number)"
PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)")

echo "→ gcloud iam service-accounts add-iam-policy-binding ${SA_EMAIL} --role=roles/iam.workloadIdentityUser"
gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-actions/attribute.repository/${REPO_OWNER}/${REPO_NAME}"

echo "✓ IAM binding created"

# Step 4: Get Provider Resource Name
echo ""
echo "[Step 4/4] Getting WIF Provider resource name..."
echo "→ gcloud iam workload-identity-pools providers describe github-provider"
PROVIDER_NAME=$(gcloud iam workload-identity-pools providers describe "github-provider" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github-actions" \
  --format="value(name)")

echo "✓ Configuration complete!"
echo ""
echo "=========================================="
echo "Next Steps - GitHub Secrets Configuration"
echo "=========================================="
echo ""
echo "Add the following secrets to your GitHub repository:"
echo "(Settings → Secrets and variables → Actions → New repository secret)"
echo ""
echo "1. Secret name: WIF_PROVIDER"
echo "   Value:"
echo "   ${PROVIDER_NAME}"
echo ""
echo "2. Secret name: WIF_SERVICE_ACCOUNT"
echo "   Value:"
echo "   ${SA_EMAIL}"
echo ""
echo "=========================================="
echo "Verification Commands"
echo "=========================================="
echo ""
echo "# Verify WIF Pool:"
echo "gcloud iam workload-identity-pools describe github-actions \\"
echo "  --project=${PROJECT_ID} \\"
echo "  --location=global"
echo ""
echo "# Verify WIF Provider:"
echo "gcloud iam workload-identity-pools providers describe github-provider \\"
echo "  --project=${PROJECT_ID} \\"
echo "  --location=global \\"
echo "  --workload-identity-pool=github-actions"
echo ""
echo "# Verify IAM Binding:"
echo "gcloud iam service-accounts get-iam-policy \\"
echo "  ${SA_EMAIL} \\"
echo "  --project=${PROJECT_ID}"
echo ""
