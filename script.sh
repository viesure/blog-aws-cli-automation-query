#!/bin/bash

###########################
#  Account ID and Region  #
###########################

# get current AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
# get current AWS REGION to use in URLs
REGION=$(aws configure get region)

echo "Your account ID is ${ACCOUNT_ID}"
echo "Your region is ${REGION}"
echo ""

###########################
#  REST Gateway Endpoint  #
###########################
echo "Creating Gateway for test..."
STACKNAME=viesure-blog-gateway
aws cloudformation deploy --template-file api_template.yaml --stack-name ${STACKNAME}
# Wait for the Gateway to be available.
# This may take a while since the wait command only checks every 30s
aws cloudformation wait stack-create-complete --stack-name ${STACKNAME}

REST_API_ID=$(aws apigateway get-rest-apis --query 'items[?name==`viesure-blog-gateway`].id' --output text)
STAGE=test
API_URL=https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/${STAGE}
echo "Your API URL is ${API_URL}"
ENDPOINT=${API_URL}/helloworld
echo "calling the endpoint ${ENDPOINT}"
if curl --fail ${ENDPOINT} ; then
  echo "Successfully called API!"
else
  echo "Failed to call API"
fi

echo "Deleting gateway..."
aws cloudformation delete-stack --stack-name ${STACKNAME}
echo ""

####################################
#  Elastic Container Registry URL  #
####################################
echo "Creating ECR repository for test..."
REPOSITORY=viesure-blog-repository
# we could use the output of create-repository too... but that'd defeat the purpose of the demonstration ;)
aws ecr create-repository --repository-name ${REPOSITORY} > /dev/null
ECR_URL_CONSTRUCTED=${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPOSITORY}
ECR_URL_QUERIED=$(aws ecr describe-repositories --repository-names ${REPOSITORY} --query 'repositories[*].repositoryUri' --output text)
echo "Constructed ECR URL: ${ECR_URL_CONSTRUCTED}"
echo "Constructed ECR URL: ${ECR_URL_QUERIED}"

echo "Deleting repository..."
aws ecr delete-repository --repository-name ${REPOSITORY} > /dev/null
