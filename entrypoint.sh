#!/bin/bash

set -e

if [[ -z "$TEMPLATE" ]]; then
    echo "Empty template specified. Looking for template.yaml..."

    if [[ ! -f "template.yaml" ]]; then
        echo template.yaml not found
        exit 1
    fi

    TEMPLATE="template.yaml"
fi

if [[ -z "$AWS_STACK_NAME" ]]; then
    echo AWS Stack Name invalid
    exit 1
fi

if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
    echo AWS Access Key ID invalid
    exit 1
fi

if [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
    echo AWS Secret Access Key invalid
    exit 1
fi

if [[ -z "$AWS_REGION" ]]; then
    echo AWS Region invalid
    exit 1
fi

if [[ -z "$AWS_DEPLOY_BUCKET" ]]; then
    echo AWS Deploy Bucket invalid
    exit 1
fi

if [[ ! -z "$AWS_BUCKET_PREFIX" ]]; then
    AWS_BUCKET_PREFIX="--s3-prefix ${AWS_BUCKET_PREFIX}"
fi

if [[ $FORCE_UPLOAD == true ]]; then
    FORCE_UPLOAD="--force-upload"
fi

if [[ $NO_FAIL_EMPTY_CHANGESET == true ]]; then
    NO_FAIL_EMPTY_CHANGESET="--no-fail-on-empty-changeset"
fi

if [[ $USE_JSON == true ]]; then
    USE_JSON="--use-json"
fi

if [[ -z "$CAPABILITIES" ]]; then
    CAPABILITIES="--capabilities CAPABILITY_IAM"
else
    CAPABILITIES="--capabilities $CAPABILITIES"
fi

if [[ ! -z "$PARAMETER_OVERRIDES" ]]; then
    PARAMETER_OVERRIDES="--parameter-overrides $PARAMETER_OVERRIDES"
fi

if [[ ! -z "$TAGS" ]]; then
    TAGS="--tags $TAGS"
fi

mkdir -p ~/.aws
touch ~/.aws/credentials
touch ~/.aws/config

echo "[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
region = $AWS_REGION" >~/.aws/credentials

echo "[default]
output = text
region = $AWS_REGION" >~/.aws/config

aws configure set default.s3.multipart_threshold 256MB
aws configure set default.s3.multipart_chunksize 64MB

# cat ~/.aws/config

# create buckets if not exists
# if aws s3api head-bucket --bucket "$AWS_DEPLOY_BUCKET" --region $AWS_REGION 2>/dev/null; then
#   echo $AWS_DEPLOY_BUCKET exists!
# else
#   echo $AWS_DEPLOY_BUCKET not exists and going to create it!
#   aws s3 mb s3://$AWS_DEPLOY_BUCKET --region $AWS_REGION
#   echo "$AWS_DEPLOY_BUCKET is created"
# fi

aws cloudformation package --template-file $TEMPLATE --output-template-file serverless-output.yaml --s3-bucket $AWS_DEPLOY_BUCKET $AWS_BUCKET_PREFIX $FORCE_UPLOAD $USE_JSON
aws cloudformation deploy --template-file serverless-output.yaml --stack-name $AWS_STACK_NAME --s3-bucket $AWS_DEPLOY_BUCKET $CAPABILITIES $PARAMETER_OVERRIDES $TAGS $NO_FAIL_EMPTY_CHANGESET
