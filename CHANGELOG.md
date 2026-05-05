# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2026-05-05

### Changed
- Updated minimum required AWS provider version from `>= 3.0` to `>= 5.0`. This drops
  implicit compatibility with provider v3/v4 (both of which had significant breaking changes
  around S3 resources). All module resources are fully compatible with AWS provider v5.x and v6.x.
- Updated GitHub Actions workflow action versions:
  - `actions/checkout` v3 → v4
  - `hashicorp/setup-terraform` v2 → v3
  - `google-github-actions/auth` v1 → v2
  - `aws-actions/configure-aws-credentials` v1 → v4
- Updated CI Terraform version from 1.3.7 to 1.10.5.

## [0.4.0] - 2024-03-08

### Changed
- Updated deep link params for Worklytics data export configuration URL.

## [0.3.0] - 2023-xx-xx

### Added
- Additional variables for improved configuration flexibility.

## [0.2.0] - 2023-xx-xx

### Added
- Restrictive `aws_s3_bucket_public_access_block` on S3 bucket (enabled by default,
  controllable via `enable_aws_s3_bucket_public_access_block` variable).
- `todo_markdown` output for environments where filesystem access is limited
  (e.g., Terraform Cloud/Enterprise).

## [0.1.0] - 2023-xx-xx

### Added
- Initial release.
- `aws_s3_bucket` for Worklytics data export destination.
- `aws_iam_role` allowing Worklytics tenant to assume via GCP Workload Identity Federation.
- `aws_iam_policy` and `aws_iam_policy_attachment` granting S3 read/write access to the role.
- `todos_as_local_files` variable to render setup instructions as a local markdown file.
