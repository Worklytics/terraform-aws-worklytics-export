# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- GitHub code scanning still reported S3 versioning (AVD-AWS-0090) and access logging
  (AVD-AWS-0089) after v1.0.0. Those resources are opt-in and Trivy evaluates `count` from
  defaults (`false` / `null`), so the bucket looks unconfigured. Ignore them the same way
  encryption is ignored, and skip scanning `examples/` so the registry copy of the module
  is not reported as a second finding.

## [1.0.0] - 2026-08-17

### Breaking Changes
- Minimum required AWS provider version raised from `>= 3.0` to `>= 5.0`, required by the
  standalone `aws_s3_bucket_versioning` and `aws_s3_bucket_logging` resources. Callers still
  on provider v3/v4 will need to upgrade.

### Added
- Optional `enable_aws_s3_bucket_versioning` flag (default `false`) to enable versioning on
  the export bucket.
- Optional `aws_s3_access_log_bucket` / `aws_s3_access_log_prefix` inputs to configure S3
  server access logging when a destination bucket is provided.

### Changed
- Integration CI now matrices AWS provider majors `~> 5.0` and `~> 6.0` (dropped `~> 3.0`).

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
- Slimmed CI Terraform version matrices:
  - lint: oldest supported (`~1.1.0`) + `latest`
  - validate / integration: oldest, a couple intermediates, and latest
- Integration also matrices AWS provider majors `~> 3.0` and `~> 6.0`, with
  workflow concurrency + `max-parallel` to limit contention on the shared CI account.
  Terraform 1.0 is excluded because the `moved` block requires `>= 1.1`.

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
