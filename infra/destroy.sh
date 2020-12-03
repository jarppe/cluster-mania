#!/usr/bin/env bash

echo "Clean up resources created in init.sh"
echo "Run after 'terraform destroy'"
echo

read -r -p "Are you sure you want to destroy resources of this project? (y/N) " response
if [[ ! "$response" =~ ^(yes|y)$ ]]; then
  echo "Aborted"
  exit 1
fi


echo "Cleanup .env..."
sed -i "s/^TF_VAR_PROJECT_FOLDER_ID=.*\$/TF_VAR_PROJECT_FOLDER_ID=/" .env


echo "Delete bucket..."
gsutil rm "gs://${TF_VAR_BUCKET}"


echo "Unlink billing account..."
gcloud beta billing projects unlink ${TF_VAR_PROJECT_ID}


echo "Delete configuration..."
gcloud config configurations activate  default
gcloud config configurations delete    ${TF_VAR_PROJECT_ID}  --quiet


echo "Delete project..."
gcloud projects delete ${TF_VAR_PROJECT_ID}


echo "Delete project folder..."
gcloud resource-manager folders delete ${TF_VAR_PROJECT_FOLDER_ID}


echo "Delete project SA..."
gcloud iam service-accounts delete ${TF_VAR_SA_NAME} --project=${TF_VAR_PROJECT_ID}


echo "Delete creds..."
rm -fr "${TF_VAR_CREDS}"


echo
echo "==================================================================================="
echo "It's like it never existed"
echo "==================================================================================="
echo
