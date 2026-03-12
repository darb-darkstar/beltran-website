# CI/CD Pipeline

Deployments are handled using *GitHub Actions*.

## Workflow

Developer Push
     │
     ▼
GitHub Actions
     │
OIDC Authentication
     │
Assume AWS IAM Role
     │
Terraform Infrastructure
     │
Upload Website to S3
     │
Invalidate CloudFront Cache

## Deployment Strategy

| Branch | Environment |
|------|------|
| dev | Dev environment |
| main | Production |

## Authentication

Authentication is handled via *OIDC*, eliminating the need for static AWS credentials.

GitHub assumes the IAM role:

beltran-website-github-actions-role

## Deployment Steps

1. Authenticate with AWS via OIDC
2. Initialize Terraform environment
3. Retrieve infrastructure outputs
4. Sync website files to S3
5. Invalidate CloudFront cache