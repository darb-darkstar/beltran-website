# Infrastructure

Infrastructure is managed using *Terraform* with modular architecture.

## Repository Structure

terraform/
│
├── global
│   ├── github_oidc.tf
│   ├── github_actions_role.tf
│   └── backend.tf
│
├── environments
│   ├── dev
│   └── production
│
└── modules
    └── static-site

## Global Infrastructure

The global stack creates shared resources:

- GitHub OIDC identity provider
- GitHub Actions IAM role
- Terraform backend configuration

## Environment Infrastructure

Each environment deploys:

- S3 website bucket
- CloudFront distribution
- Route53 DNS records
- SSL certificates via ACM

## Terraform State

Remote state is stored in:

- *S3:* beltran-terraform-state
- *DynamoDB:* terraform-locks

This enables safe multi-user Terraform workflows.