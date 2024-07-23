#!/bin/bash

envs=("dev" "prod")
read -p "Enter the billing account ID: " BILLING_ACCOUNT_ID #0171C3-085B94-E5D89A
read -p "Enter the desired location: " LOCATION 

for env in "${envs[@]}"; do 
    project_name="$env-ingenius-app"
    existing_project=$(gcloud projects list --format="value(NAME)" --filter=$project_name)
    if [ "$existing_project" != "$project_name" ]; then
        random_number=$(printf "%06d" $(( (RANDOM * 32768 + RANDOM) % 1000000 )))
        project_id="$project_name-$random_number"
        tf_state_bucket_name="$project_id-tf-state"
        gcloud projects create $project_id --name=$project_name
        gcloud beta billing projects link $project_id --billing-account=$BILLING_ACCOUNT_ID
        echo "Project $project_id created and billing account $BILLING_ACCOUNT_ID linked."
        gcloud config set project $project_id
        gcloud storage buckets create gs://$tf_state_bucket_name --location=$LOCATION
    else
        echo "Project $project_name already exists."
        project_id=$(gcloud projects list --format="value(PROJECT_ID)" --filter=$project_name)
        gcloud config set project $project_id
        tf_state_bucket_name=$(gcloud storage buckets list --format="value(NAME)" --filter=$project_id)
    fi

    export ENV="$env"    
    export PROJECT_ID="$project_id"
    export PROJECT_NAME="$project_name"
    export TF_STATE_BUCKET="$tf_state_bucket_name"
    envsubst < tfvars.template >> values.auto.tfvars 
    echo "Configuration generated for ${env}"
done
