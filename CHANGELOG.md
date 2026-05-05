# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2026-05-05

### Changed
- AWS provider floor retained at `>= 3.0` (unchanged). The module's resource usage
  (`aws_s3_bucket_public_access_block`, `aws_iam_*`, etc.) only requires v2.42+, so
  the original floor remains accurate.
- Updated GitHub Actions workflow action versions:
  - `actions/checkout` v3 → v6
  - `hashicorp/setup-terraform` v2 → v3
  - `google-github-actions/auth` v1 → v2
  - `aws-actions/configure-aws-credentials` v1 → v4
- Updated CI Terraform version to 1.15.1 for lint/validate workflows.
- Expanded integration test matrix to cover all Terraform 1.1–1.15 minor versions
  × all AWS provider major series 3.x–6.x (60 combinations). Note: Terraform 1.0 is
  excluded because the `moved` block used in this module requires `>= 1.1`.

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
