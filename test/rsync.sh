#!/bin/bash

# Usage:
# ./rsync.sh

EXAMPLE_TENANT_SA_EMAIL=$1
BUCKET_NAME=$2
IAM_ROLE_ARN=$3

# https://cloud.google.com/sdk/gcloud/reference/auth/print-identity-token
CI_RUN=`date +%Y%m%d'T'%H%M%S`

# should work, assuming you're running this somewhere that your gcloud CLI is auth'd as something
# that can impersonate the target service account
GCP_TOKEN=`gcloud auth print-identity-token --impersonate-service-account=${EXAMPLE_TENANT_SA_EMAIL}`

aws sts assume-role-with-web-identity --role-arn IAM_ROLE_ARN --role-session-name "ci-run-${CI_RUN}" --web-identity-token $GCP_TOKEN --provider-id "accounts.google.com" > /tmp/assume-role.json

# if bucket exists + perms OK, this should work
s3 sync . s3://$BUCKET_NAME/${CI_RUN}