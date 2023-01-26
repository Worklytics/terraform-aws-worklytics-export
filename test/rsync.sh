#!/bin/bash

# Usage:
# ./rsync.sh

EXAMPLE_TENANT_SA_EMAIL=$1
BUCKET_NAME=`terraform output worklytics_export_bucket.name`
IAM_ROLE_ARN=`terraform output worklytics_tenant_aws_role.arn`

# https://cloud.google.com/sdk/gcloud/reference/auth/print-identity-token
CI_RUN=`date +%Y%m%d'T'%H%M%S`

# should work, assuming you're running this somewhere that your gcloud CLI is auth'd as something
# that can impersonate the target service account
GCP_TOKEN=`gcloud auth print-identity-token --impersonate-service-account=${EXAMPLE_TENANT_SA_EMAIL}`

echo "BUCKET_NAME: ${BUCKET_NAME}\n"
echo "IAM_ROLE_ARN: ${IAM_ROLE_ARN}\n"

export $(printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s" \
$(aws sts assume-role-with-web-identity \
--role-arn $IAM_ROLE_ARN \
--role-session-name "ci-run-${CI_RUN}" \
--web-identity-token $GCP_TOKEN \
--provider-id "accounts.google.com" \
--query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" \
--output text))

# NOTE : presuming that it's OK we overwrote prior AWS env vars, bc next gh action run will reset

# if bucket exists + perms OK, this should work
aws s3 sync . s3://$BUCKET_NAME/${CI_RUN}
