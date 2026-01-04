# Workload Identity Federation for GitHub Actions

## Overview

This project uses Workload Identity Federation (WIF) to authenticate GitHub Actions workflows to Google Cloud without storing service account keys. This eliminates the need for long-lived credentials and follows GCP security best practices.

## Architecture

**Authentication Flow:**
```
GitHub Actions Workflow
    ↓ (requests OIDC token)
GitHub OIDC Provider
    ↓ (issues short-lived token)
Google Cloud Security Token Service (STS)
    ↓ (validates token and attribute conditions)
GCP Service Account Impersonation
    ↓ (grants temporary credentials)
Access to GCP Resources
```

**Configuration:**
- **Provider:** GitHub OIDC (`https://token.actions.githubusercontent.com`)
- **Pool:** `github-actions` (in `tf-gcp-proj-main` project)
- **Provider ID:** `github-provider`
- **Service Account:** `terraform-sa@tf-gcp-proj-main.iam.gserviceaccount.com`
- **Scope:** Repository-specific (only workflows from `gitmpr/private_repo_spring-petclinic`)

## Security Benefits

### Comparison: JSON Key vs OIDC

| Aspect | JSON Service Account Key | OIDC via WIF |
|--------|-------------------------|--------------|
| **Credential Storage** | Key stored in GitHub secret | No credentials stored |
| **Credential Lifetime** | Until manually rotated | 10 minutes (auto-expired) |
| **Rotation** | Manual process | Automatic |
| **Revocation** | Delete key, create new one | Remove IAM binding |
| **Audit Trail** | Generic service account activity | Includes GitHub workflow context (repo, branch, actor) |
| **Leak Impact** | Permanent access until rotated | Maximum 10-minute access window |
| **Attack Surface** | Anyone with secret has access | Scoped to specific repository owner |
| **Best Practices** | Considered legacy | Google Cloud recommended approach |

### Key Security Improvements

1. **No Long-Lived Credentials**
   - OIDC tokens expire after 10 minutes
   - No risk of forgotten or leaked credentials persisting

2. **Automatic Rotation**
   - New token issued for each workflow run
   - No manual key rotation procedures needed

3. **Repository Scoping**
   - Attribute condition restricts access to specific repository owner
   - Even if token is leaked, only works from authorized repository

4. **Enhanced Audit Trail**
   - Cloud Logging shows which GitHub workflow/run accessed what resources
   - Includes actor (GitHub user who triggered workflow)
   - Includes repository, branch, and commit SHA

5. **Easier Compliance**
   - Eliminates need to track and rotate service account keys
   - Reduces compliance burden for credential management

## How It Works

### Token Claims

GitHub OIDC tokens include these claims (mapped in WIF provider):

- `sub` (subject): `repo:OWNER/REPO:ref:refs/heads/BRANCH`
- `repository`: Full repo name (`gitmpr/private_repo_spring-petclinic`)
- `repository_owner`: Repository owner (`gitmpr`)
- `actor`: GitHub username who triggered the workflow
- `workflow`: Workflow file name
- `ref`: Git ref (branch or tag)
- `sha`: Git commit SHA

### Attribute Mapping

The WIF provider maps GitHub token claims to GCP attributes:

```
google.subject         = assertion.sub
attribute.actor        = assertion.actor
attribute.repository   = assertion.repository
attribute.repository_owner = assertion.repository_owner
```

### Attribute Condition (Security Constraint)

```
assertion.repository_owner == 'gitmpr'
```

This ensures only workflows from repositories owned by `gitmpr` can authenticate, even if the token is leaked to another repository.

### IAM Binding

The service account has this IAM binding:

```yaml
role: roles/iam.workloadIdentityUser
member: principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions/attribute.repository/gitmpr/private_repo_spring-petclinic
```

This allows only workflows from the specific repository to impersonate the service account.

## Configuration

### GCP Setup

The following resources were created in the `tf-gcp-proj-main` project:

1. **Workload Identity Pool**
   - ID: `github-actions`
   - Location: `global`
   - Purpose: Container for identity providers

2. **Workload Identity Provider**
   - ID: `github-provider`
   - Type: OIDC
   - Issuer: `https://token.actions.githubusercontent.com`
   - Attribute mapping: Maps GitHub claims to GCP attributes
   - Attribute condition: Restricts to repository owner

3. **IAM Binding**
   - Role: `roles/iam.workloadIdentityUser`
   - Member: Specific to repository
   - Effect: Allows GitHub Actions to impersonate service account

### GitHub Secrets

Two secrets are configured in the GitHub repository:

1. **`WIF_PROVIDER`**
   - Format: `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions/providers/github-provider`
   - Purpose: Identifies the WIF provider to authenticate with

2. **`WIF_SERVICE_ACCOUNT`**
   - Value: `terraform-sa@tf-gcp-proj-main.iam.gserviceaccount.com`
   - Purpose: Service account to impersonate

### GitHub Actions Workflow

The workflow uses the `google-github-actions/auth@v2` action with OIDC parameters:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write  # Required for OIDC

    steps:
      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
          service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}
```

The `id-token: write` permission is critical - it allows the workflow to request an OIDC token from GitHub.

## Verification

### Verify WIF Pool

```bash
gcloud iam workload-identity-pools describe github-actions \
  --project=tf-gcp-proj-main \
  --location=global
```

Expected output should show:
- Name: `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions`
- Display Name: "GitHub Actions Workload Identity Pool"
- State: ACTIVE

### Verify WIF Provider

```bash
gcloud iam workload-identity-pools providers describe github-provider \
  --project=tf-gcp-proj-main \
  --location=global \
  --workload-identity-pool=github-actions
```

Expected output should show:
- Issuer URI: `https://token.actions.githubusercontent.com`
- Attribute mapping for subject, actor, repository, repository_owner
- Attribute condition restricting to repository owner

### Verify IAM Binding

```bash
gcloud iam service-accounts get-iam-policy \
  terraform-sa@tf-gcp-proj-main.iam.gserviceaccount.com \
  --project=tf-gcp-proj-main \
  --format=json | jq '.bindings[] | select(.role == "roles/iam.workloadIdentityUser")'
```

Expected output should show:
- Role: `roles/iam.workloadIdentityUser`
- Member: `principalSet://iam.googleapis.com/projects/.../attribute.repository/gitmpr/private_repo_spring-petclinic`

### Test Authentication in Workflow

Successful authentication in GitHub Actions logs shows:

```
Authenticating to Google Cloud...
Successfully authenticated to Google Cloud
```

Failed authentication shows error messages like:
- `Error: invalid_grant` - WIF provider resource name incorrect
- `Error: Permission denied` - IAM binding missing or incorrect
- `Error: Attribute condition not met` - Repository owner mismatch

## Troubleshooting

### Authentication Fails with "invalid_grant"

**Cause:** WIF provider resource name is incorrect in GitHub secret

**Solution:**
1. Get the correct provider name:
   ```bash
   gcloud iam workload-identity-pools providers describe github-provider \
     --project=tf-gcp-proj-main \
     --location=global \
     --workload-identity-pool=github-actions \
     --format="value(name)"
   ```
2. Update the `WIF_PROVIDER` secret in GitHub with the full output

### Authentication Fails with "Permission denied"

**Cause:** IAM binding is missing or incorrect

**Solution:**
```bash
PROJECT_NUMBER=$(gcloud projects describe tf-gcp-proj-main --format="value(projectNumber)")

gcloud iam service-accounts add-iam-policy-binding \
  terraform-sa@tf-gcp-proj-main.iam.gserviceaccount.com \
  --project=tf-gcp-proj-main \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-actions/attribute.repository/gitmpr/private_repo_spring-petclinic"
```

### Authentication Fails with "Attribute condition not met"

**Cause:** Workflow is running from a fork or different repository owner

**Solution:**
- Ensure the workflow runs from the main repository (`gitmpr/private_repo_spring-petclinic`), not a fork
- If the repository owner changed, update the attribute condition in the WIF provider

### Workflow Fails with "id-token: write permission required"

**Cause:** Missing OIDC permission in workflow

**Solution:** Add to job definition:
```yaml
permissions:
  contents: read
  id-token: write
```

## Migration Notes

**Migration Date:** 2026-01-04

**Before:**
- GitHub secret `TERRAFORM_GCP_SA_KEY` contained JSON service account key
- Service account: `terraform-sa@tf-gcp-proj-main.iam.gserviceaccount.com`
- Authentication method: Static JSON key file

**After:**
- GitHub secrets `WIF_PROVIDER` and `WIF_SERVICE_ACCOUNT`
- Same service account, different authentication method
- Authentication method: OIDC via Workload Identity Federation

**Breaking Changes:**
- The `deploy-cloud-run.yml` workflow is non-functional after migration
  - This is intentional - Cloud Run deployment is legacy
  - Project has fully migrated to GKE
  - File kept for reference only

**Rollback Plan:**
If OIDC authentication fails, rollback is possible:
1. Recreate service account key:
   ```bash
   gcloud iam service-accounts keys create terraform-gcp-sa-key.json \
     --iam-account=terraform-sa@tf-gcp-proj-main.iam.gserviceaccount.com
   ```
2. Add key back to GitHub secrets as `TERRAFORM_GCP_SA_KEY`
3. Revert workflow changes to use `credentials_json` parameter

## Future Considerations

### Kubernetes API Server OIDC (Separate Enhancement)

The current WIF implementation handles **GitHub Actions → GCP** authentication.

A separate future enhancement could configure **External Users → Kubernetes API** authentication using OIDC. This would allow `kubectl` access without `gcloud` credentials.

**Reference:** [GKE OIDC Authentication](https://cloud.google.com/kubernetes-engine/docs/how-to/oidc)

**Note:** This is independent of CI/CD OIDC and not required for deployments to function.

### Branch Restrictions

Currently, any branch in the repository can trigger workflows with OIDC authentication.

**Optional Enhancement:** Restrict to specific branches:
```
assertion.repository_owner == 'gitmpr' && assertion.ref == 'refs/heads/main'
```

This would require workflows to run from the `main` branch only.

### Environment Protection Rules

GitHub environment protection rules can add additional security:
- Require reviewers for prod deployments
- Add wait timer before deployment
- Restrict deployments to specific branches
- Limit which users can trigger deployments

These work alongside OIDC and are configured in GitHub repo settings.

## References

- [Google Cloud WIF for GitHub Actions](https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)
- [GitHub OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [google-github-actions/auth](https://github.com/google-github-actions/auth) - GitHub Action for authentication
- [OIDC Token Claims](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#understanding-the-oidc-token)
- [GCP Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)

## Maintenance

### When Adding New Repositories

If you need to grant OIDC access to additional repositories:

1. Update the attribute condition in the WIF provider to include the new repository
2. Add a new IAM binding for the new repository
3. Configure the same GitHub secrets in the new repository

### When Changing Repository Owner

If the repository is transferred to a new owner:

1. Update the attribute condition in the WIF provider:
   ```bash
   gcloud iam workload-identity-pools providers update-oidc github-provider \
     --project=tf-gcp-proj-main \
     --location=global \
     --workload-identity-pool=github-actions \
     --attribute-condition="assertion.repository_owner == 'NEW_OWNER'"
   ```

2. Update the IAM binding member to reflect the new repository path

### Monitoring and Auditing

View authentication events in Cloud Logging:

```bash
gcloud logging read \
  'protoPayload.authenticationInfo.principalEmail="terraform-sa@tf-gcp-proj-main.iam.gserviceaccount.com"' \
  --project=tf-gcp-proj-main \
  --limit=50 \
  --format=json
```

This shows all operations performed by the service account, including which GitHub workflow triggered each operation.
