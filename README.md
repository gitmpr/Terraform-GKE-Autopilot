# Terraform + GKE Learning Project

A hands-on learning project for deploying a Spring Boot application (PetClinic) to Google Cloud using **Terraform** for infrastructure-as-code and **GKE Autopilot** for container orchestration.

## What This Project Covers

- Multi-project GCP setup with environment separation (main, test, prod)
- Terraform stacks with remote state and workspaces
- GKE Autopilot clusters with Kustomize-based deployments
- Cloud SQL PostgreSQL with private networking and Cloud SQL Proxy
- Workload Identity Federation for keyless CI/CD authentication
- GitHub Actions pipelines for infrastructure and application deployment
- Gateway API for external load balancing

## Architecture Overview

```
GCP Projects
├── tf-gcp-proj-main
│   ├── Terraform state
│   ├── Artifact Registry
│   └── Service accounts
├── tf-gcp-proj-test
│   ├── GKE Autopilot cluster
│   ├── Cloud SQL PostgreSQL
│   └── VPC with private service access
└── tf-gcp-proj-prod
    ├── GKE Autopilot cluster
    ├── Cloud SQL PostgreSQL
    └── VPC with private service access
```

## Repository Structure

```
.
├── terraform/
│   └── stacks/
│       ├── shared/             Artifact Registry, shared resources
│       │   ├── backend.tf
│       │   ├── main.tf
│       │   └── variables.tf
│       └── env/                Per-environment infrastructure (uses workspaces)
│           ├── backend.tf
│           ├── gke.tf          GKE Autopilot cluster
│           ├── cloud-sql.tf    Cloud SQL PostgreSQL
│           ├── networking.tf   VPC, subnets, private service access
│           ├── service-accounts.tf
│           └── env.d/
│               ├── test.tfvars
│               └── prod.tfvars
├── k8s/
│   ├── base/                   Shared Kubernetes manifests
│   │   ├── deployment.yaml     App + Cloud SQL Proxy sidecar
│   │   ├── service.yaml
│   │   ├── gateway.yaml        Gateway API load balancer
│   │   └── httproute.yaml
│   └── overlays/               Environment-specific patches (Kustomize)
│       ├── test/
│       └── prod/
├── .github/workflows/
│   ├── deploy-application.yml  Build + deploy app to GKE
│   └── deploy-terraform.yml    Plan + apply Terraform changes
├── Dockerfile
├── gcp_deploy_steps.txt        Step-by-step GCP setup guide
└── PETCLINIC.md                Spring PetClinic application docs
```

## Key Concepts Explored

### Terraform

- **Stacks pattern**: Separate Terraform roots for shared vs environment-specific resources
- **Workspaces**: `test` and `prod` workspaces within the `env` stack, using `env.d/*.tfvars` for configuration
- **Remote state**: GCS backend with versioning (`gs://tf-gcp-proj-main-tfstate`)
- **Cross-project management**: Single service account managing resources across three GCP projects

### GKE and Kubernetes

- **GKE Autopilot**: Fully managed node infrastructure with per-pod billing
- **Kustomize overlays**: Base manifests with environment-specific patches for replicas, service accounts, and database connections
- **Gateway API**: Cloud Load Balancer provisioned declaratively via Kubernetes resources
- **Cloud SQL Proxy sidecar**: Secure database connectivity over private IP using Workload Identity

### CI/CD and Security

- **Workload Identity Federation**: GitHub Actions authenticates to GCP via OIDC -- no service account keys stored in CI
- **Secret Manager**: Database passwords stored in GCP Secret Manager, injected at deploy time
- **Workload Identity**: Kubernetes pods authenticate to GCP services without key files

## Getting Started

### Prerequisites

- Google Cloud SDK (`gcloud`)
- Terraform >= 1.5
- `kubectl`
- Docker

### Initial Setup

The full step-by-step GCP project setup is documented in [`gcp_deploy_steps.txt`](gcp_deploy_steps.txt). This covers:

1. Creating and linking GCP projects
2. Enabling required APIs
3. Creating the Terraform state bucket
4. Setting up the Terraform service account
5. Deploying infrastructure with Terraform
6. Building and pushing the container image
7. Deploying to GKE

### Deploying via GitHub Actions

Once the initial infrastructure is in place, deployments are managed through GitHub Actions:

- **Infrastructure changes**: Use the "Deploy Terraform Infrastructure" workflow with plan-only mode for review
- **Application deployments**: Use the "Deploy Application to GKE" workflow, selecting the target environment

See [`.github/workflows/README.md`](.github/workflows/README.md) for detailed workflow documentation.

## Related Documentation

| Document | Description |
|----------|-------------|
| [PETCLINIC.md](PETCLINIC.md) | Spring PetClinic application (building, running, database config) |
| [gcp_deploy_steps.txt](gcp_deploy_steps.txt) | Step-by-step GCP project and infrastructure setup |
| [k8s/README.md](k8s/README.md) | Kubernetes deployment guide and troubleshooting |
| [.github/workflows/README.md](.github/workflows/README.md) | CI/CD workflow documentation |
| [WORKLOAD_IDENTITY_FEDERATION.md](WORKLOAD_IDENTITY_FEDERATION.md) | OIDC setup for keyless GitHub Actions authentication |
| [docs/MULTI_ENVIRONMENT_SINGLE_CLUSTER.md](docs/MULTI_ENVIRONMENT_SINGLE_CLUSTER.md) | Architecture decision: separate vs shared clusters |
