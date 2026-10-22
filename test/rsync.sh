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

echo "EXAMPLE_TENANT_SA_EMAIL: ${EXAMPLE_TENANT_SA_EMAIL}"
echo "BUCKET_NAME: ${BUCKET_NAME}"
echo "IAM_ROLE_ARN: ${IAM_ROLE_ARN}"

MAX_ATTEMPTS=6
for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  if CREDS=$(aws sts assume-role-with-web-identity \
    --role-arn "$IAM_ROLE_ARN" \
    --role-session-name "ci-run-${CI_RUN}" \
    --web-identity-token "$GCP_TOKEN" \
    --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" \
    --output text 2>/dev/null); then
    # shellcheck disable=SC2046
    export $(printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s" $CREDS)
    break
  fi
  if [ "$attempt" -eq "$MAX_ATTEMPTS" ]; then
    echo "AssumeRoleWithWebIdentity failed after ${MAX_ATTEMPTS} attempts"
    aws sts assume-role-with-web-identity \
      --role-arn "$IAM_ROLE_ARN" \
      --role-session-name "ci-run-${CI_RUN}" \
      --web-identity-token "$GCP_TOKEN"
    exit 1
  fi
  echo "AssumeRoleWithWebIdentity failed (attempt ${attempt}/${MAX_ATTEMPTS}), retrying..."
  sleep $((attempt * 5))
done

# there's a provider-id arg, but gives error that you shouldn't send it w openid token
# --provider-id "accounts.google.com" \

# NOTE : presuming that it's OK we overwrote prior AWS env vars, bc next gh action run will reset

# if bucket exists + perms OK, this should work
mkdir /tmp/$CI_RUN
echo "TEST" > /tmp/$CI_RUN/test.txt
aws s3 sync /tmp/$CI_RUN s3://$BUCKET_NAME
