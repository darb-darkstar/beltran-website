# Architecture Overview

This project deploys a static portfolio website using AWS infrastructure managed with Terraform and deployed through GitHub Actions.

## High Level Architecture

mermaid
flowchart TD

A[Developer Push] --> B[GitHub Actions CI/CD]

B --> C[OIDC Authentication]
C --> D[AWS IAM Role]

D --> E[Terraform Infrastructure]

E --> F[S3 Static Website Bucket]
F --> G[CloudFront CDN]
G --> H[Route53 DNS]

H --> I[Users Access Website]

## Environments

Two isolated environments are managed:

| Environment | Branch | Domain |
|-------------|-------|------|
| Dev | dev | dev.bradbeltran.com |
| Production | main | www.bradbeltran.com |

## Key Infrastructure Components

| Service | Purpose |
|------|------|
| *S3* | Static website hosting |
| *CloudFront* | Global CDN + HTTPS |
| *Route53* | DNS management |
| *IAM OIDC* | Secure GitHub authentication |
| *Terraform* | Infrastructure as Code |
| *GitHub Actions* | CI/CD pipeline |