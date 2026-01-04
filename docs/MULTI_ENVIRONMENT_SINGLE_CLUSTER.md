# Multi-Environment Single Cluster Consideration

## Current Architecture

Currently, we deploy one GKE cluster per environment:
- **Test Environment**: `gorillaclinic-k8s-gke-test` cluster in `tf-gcp-proj-test` project
- **Prod Environment**: `gorillaclinic-k8s-gke-prod` cluster in `tf-gcp-proj-prod` project

Each environment has:
- Dedicated GKE Autopilot cluster
- Dedicated Cloud SQL instance
- Dedicated VPC network
- Dedicated GCP project
- Environment-specific namespace (petclinic-test, petclinic-prod)

## Alternative: Multi-Environment Single Cluster

### Concept

Host multiple lower environments (dev, test, sta, acc) on a single shared GKE cluster, while keeping production isolated.

**Example naming:**
- Cluster: `gorillaclinic-k8s-gke-nonprod` (or `dta` for "diverse test automation")
- Namespaces: `petclinic-dev`, `petclinic-test`, `petclinic-sta`, `petclinic-acc`
- Production: `gorillaclinic-k8s-gke-prod` with `petclinic-prod` namespace

### Benefits

1. **Cost Optimization**
   - Single GKE control plane instead of multiple (Autopilot charges per cluster)
   - Reduced node overhead - shared node pools across environments
   - Fewer load balancers (Gateway API can route to multiple namespaces)
   - Lower egress costs within same cluster

2. **Operational Efficiency**
   - Single cluster to monitor and maintain
   - Simplified upgrades and patching
   - Consistent configuration across lower environments
   - Easier to share common services (monitoring, logging)

3. **Resource Utilization**
   - Better bin-packing across environments
   - Workloads can share compute resources during off-peak hours
   - Autopilot optimizes across all namespaces

### Challenges

1. **Naming Complexity**
   - Cluster named "dta" but environments still named "test", "dev", etc.
   - Terraform variable `environment` doesn't match cluster name
   - Confusion between "what is the environment" vs "what is the cluster"
   - Example: `environment = "test"` but `cluster = "dta"` - non-intuitive

2. **Resource Isolation**
   - Namespaces provide logical isolation but share physical resources
   - Resource quotas required to prevent one environment from starving others
   - Network policies needed to prevent cross-namespace traffic
   - Potential for noisy neighbor problems

3. **Security Boundaries**
   - All environments share the same Kubernetes API server
   - Compromise in one namespace could potentially affect others
   - RBAC must be carefully configured per namespace
   - Workload Identity per namespace adds complexity

4. **Blast Radius**
   - Cluster-level issue affects all environments
   - Kubernetes upgrade problems impact multiple teams
   - Single point of failure for all lower environments
   - Harder to test cluster-level changes in isolation

5. **Database Separation**
   - Still need separate Cloud SQL instances per environment (can't share databases)
   - Still need separate VPCs or careful VPC configuration
   - Workload Identity bindings more complex with cross-project access

6. **GitOps and CI/CD Complexity**
   - Deploy process must distinguish between cluster and environment
   - Kustomize overlays need to handle cluster vs environment naming
   - GitHub Actions workflow parameters become more complex
   - Harder to explain to new team members

## Recommendation

### For This Project: Keep Separate Clusters

**Reasoning:**
1. **Simplicity** - One cluster per environment is easier to understand and manage
2. **Clear Boundaries** - Complete isolation between test and prod
3. **Cost is Reasonable** - Autopilot GKE costs are manageable at this scale
4. **Team Size** - Small team benefits from simpler architecture over cost optimization

### When to Consider Shared Cluster

Multi-environment single cluster makes sense when:
- **Scale**: 5+ lower environments that justify the complexity
- **Cost Pressure**: Significant budget constraints requiring optimization
- **Mature Team**: DevOps expertise to handle additional complexity
- **Standardization**: All environments have similar requirements and configurations
- **Resource Intensive**: Environments with large resource requirements that benefit from sharing

## Implementation Notes (If Pursuing Shared Cluster)

### Terraform Structure

```hcl
# Option 1: Separate cluster suffix variable
variable "environment" {
  description = "Environment name (test, dev, sta, acc)"
  type        = string
}

variable "cluster_suffix" {
  description = "Cluster name suffix (defaults to environment, override for shared clusters)"
  type        = string
  default     = null
}

locals {
  cluster_suffix = coalesce(var.cluster_suffix, var.environment)
  cluster_name   = "${var.gke_cluster_name}-${local.cluster_suffix}"
}

# In test.tfvars:
environment    = "test"
cluster_suffix = "nonprod"  # Shared cluster for all non-prod envs
```

### Namespace Strategy

- Use `namespace: petclinic-${environment}` consistently
- Kustomize overlays per environment even if sharing cluster
- Resource quotas per namespace to prevent resource starvation
- Network policies to isolate namespace traffic

### Workload Identity

- Separate GCP service account per environment namespace
- Bind to Kubernetes service account in respective namespace
- Example: `petclinic-app-test@project.iam` bound to `petclinic/petclinic` SA in `petclinic-test` namespace

## Conclusion

The "dta" (diverse test automation) concept is valid for mature organizations with many lower environments. However, for this project:

- **Current approach is appropriate**: Separate clusters provide clear boundaries and simplicity
- **Document for future**: When adding dev/sta/acc environments, revisit this decision
- **Cost monitoring**: Track GKE costs - if they become significant, reconsider
- **Team growth**: With larger team, shared cluster complexity becomes more manageable

The complexity introduced by mixed naming (cluster vs environment) outweighs the benefits at current scale.
