# Beltran Portfolio Infrastructure

This project demonstrates a *production-style DevOps infrastructure* for hosting a static website using AWS, Terraform, and GitHub Actions.

## Architecture

See the full architecture diagram:

👉 docs/architecture.md

## Tech Stack

- AWS S3 (Static Hosting)
- CloudFront CDN
- Route53 DNS
- ACM SSL Certificates
- Terraform Infrastructure as Code
- GitHub Actions CI/CD
- OIDC Authentication

## Infrastructure Features

- Multi-environment deployment (dev + production)
- Remote Terraform state
- DynamoDB state locking
- Secure OIDC authentication
- Automated CI/CD deployments

## Repository Structure

terraform/
modules/
website/
.github/workflows/
docs/

## Deployment Flow

1. Push to dev → deploy to *dev environment*
2. Merge to main → deploy to *production*