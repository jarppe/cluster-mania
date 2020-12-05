#!/usr/bin/env bash

set -e

echo "Create folder, project, and SA for new GCP project ${TF_VAR_PROJECT_ID}"
echo
echo "Run this in project init only."
echo

read -r -p "Are you sure you want to create resources for this project? (y/N) " response
if [[ ! "$response" =~ ^(yes|y)$ ]]; then
  echo "Aborted"
  exit 1
fi

echo
echo "==================================================================================="
echo "Create project folder:"
echo "==================================================================================="
echo

gcloud resource-manager folders create                         \
  --display-name=${TF_VAR_PROJECT_ID}                          \
  --folder=${TF_VAR_PLAYGROUND_FOLDER_ID}

PROJECT_FOLDER_ID=$(                                                              \
  gcloud resource-manager folders list --folder=${TF_VAR_PLAYGROUND_FOLDER_ID}    \
    | grep ${TF_VAR_PROJECT_ID}                                                   \
    | awk '{print $3}')

sed -i "s/^TF_VAR_PROJECT_FOLDER_ID=.*\$/TF_VAR_PROJECT_FOLDER_ID=${PROJECT_FOLDER_ID}/" .env

echo "Project folder ID: ${PROJECT_FOLDER_ID}"

echo
echo
echo "==================================================================================="
echo "Create project:"
echo "==================================================================================="
echo

gcloud projects create ${TF_VAR_PROJECT_ID}                    \
  --name=${TF_VAR_PROJECT_ID}                                  \
  --folder=${PROJECT_FOLDER_ID}                                \
  --set-as-default

echo
echo
echo "==================================================================================="
echo "Create configuration for project:"
echo "==================================================================================="
echo

gcloud config configurations create    ${TF_VAR_PROJECT_ID}

gcloud config set project              ${TF_VAR_PROJECT_ID}
gcloud config set compute/region       ${TF_VAR_REGION}
gcloud config set compute/zone         ${TF_VAR_ZONE}
gcloud config set account              ${TF_VAR_ACCOUNT}

gcloud config configurations activate  ${TF_VAR_PROJECT_ID}

echo
echo
echo "==================================================================================="
echo "Enable billing on main project:"
echo "==================================================================================="
echo

gcloud beta billing projects link ${TF_VAR_PROJECT_ID}         \
  --billing-account=${TF_VAR_BILLING_ACCOUNT}

echo
echo
echo "==================================================================================="
echo "Create SA for project:"
echo "==================================================================================="
echo

gcloud iam service-accounts create terraform-sa                \
    --project=${TF_VAR_PROJECT_ID}                             \
    --display-name "SA for ${TF_VAR_PROJECT_ID} project"

echo
echo
echo "==================================================================================="
echo "Enable API's for project:"
echo "==================================================================================="
echo

gcloud services enable container.googleapis.com             --project=${TF_VAR_PROJECT_ID}
gcloud services enable cloudresourcemanager.googleapis.com  --project=${TF_VAR_PROJECT_ID}
gcloud services enable cloudbilling.googleapis.com          --project=${TF_VAR_PROJECT_ID}
gcloud services enable iam.googleapis.com                   --project=${TF_VAR_PROJECT_ID}
gcloud services enable compute.googleapis.com               --project=${TF_VAR_PROJECT_ID}
gcloud services enable serviceusage.googleapis.com          --project=${TF_VAR_PROJECT_ID}
gcloud services enable oslogin.googleapis.com               --project=${TF_VAR_PROJECT_ID}
gcloud services enable networkmanagement.googleapis.com     --project=${TF_VAR_PROJECT_ID}

echo
echo
echo "==================================================================================="
echo "Grant project roles to SA:"
echo "==================================================================================="
echo

gcloud projects add-iam-policy-binding                         \
  ${TF_VAR_PROJECT_ID}                                         \
  --member serviceAccount:${TF_VAR_SA_NAME}                    \
  --role roles/viewer

gcloud projects add-iam-policy-binding                         \
  ${TF_VAR_PROJECT_ID}                                         \
  --member serviceAccount:${TF_VAR_SA_NAME}                    \
  --role roles/storage.admin

echo
echo
echo "==================================================================================="
echo "Grant organization roles to SA:"
echo "==================================================================================="
echo

gcloud organizations add-iam-policy-binding                    \
  ${TF_VAR_ORGANIZATION_ID}                                    \
  --member serviceAccount:${TF_VAR_SA_NAME}                    \
  --role roles/resourcemanager.projectCreator

gcloud organizations add-iam-policy-binding                    \
  ${TF_VAR_ORGANIZATION_ID}                                    \
  --member serviceAccount:${TF_VAR_SA_NAME}                    \
  --role roles/billing.user

echo
echo
echo "==================================================================================="
echo "Grant folder roles to SA:"
echo "==================================================================================="
echo

gcloud alpha resource-manager folders add-iam-policy-binding   \
  ${PROJECT_FOLDER_ID}                                         \
  --member=serviceAccount:${TF_VAR_SA_NAME}                    \
  --role roles/resourcemanager.projectCreator

gcloud alpha resource-manager folders add-iam-policy-binding   \
  ${PROJECT_FOLDER_ID}                                         \
  --member=serviceAccount:${TF_VAR_SA_NAME}                    \
  --role=roles/resourcemanager.folderEditor

gcloud alpha resource-manager folders add-iam-policy-binding   \
  ${PROJECT_FOLDER_ID}                                         \
  --member=serviceAccount:${TF_VAR_SA_NAME}                    \
  --role=roles/editor

echo
echo
echo "==================================================================================="
echo "Create backend bucket:"
echo "==================================================================================="
echo

gsutil mb -p ${TF_VAR_PROJECT_ID}                              \
          -c regional                                          \
          -l ${TF_VAR_REGION}                                  \
          "gs://${TF_VAR_PROJECT_ID}"

gsutil versioning set on "gs://${TF_VAR_PROJECT_ID}"

echo
echo "Upload some files for bastion:"
echo

gsutil cp ./zshenv ./zshrc ~/.ssh/id_rsa.pub "gs://${TF_VAR_PROJECT_ID}/init"

sed -i "s/^BUCKET=.*\$/BUCKET=${TF_VAR_PROJECT_ID}/" ./bastion-startup.sh

echo
echo
echo "==================================================================================="
echo "Generate credentials key file:"
echo "==================================================================================="
echo

gcloud iam service-accounts keys create ${TF_VAR_CREDS}        \
  --project ${TF_VAR_PROJECT_ID}                               \
  --iam-account ${TF_VAR_SA_NAME}

echo
echo
echo "==================================================================================="
echo "Init Terraform setup, config backend:"
echo "==================================================================================="
echo

terraform init -backend-config="bucket=${TF_VAR_PROJECT_ID}"

echo
echo
echo "==================================================================================="
echo "All done"
echo "==================================================================================="
echo
