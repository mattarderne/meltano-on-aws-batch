#!/bin/bash
NAME="meltano"
PROJECT=$(gcloud config get-value project)
IMAGE="gcr.io/$PROJECT/$NAME"
LOGS="_run-deploy-logs-$PROJECT-$NAME"

gcloud builds submit --tag $IMAGE
gcloud run deploy --allow-unauthenticated --platform=managed --image $IMAGE $NAME --memory 4Gi --timeout=1000s

gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=$NAME" --project client-meltano  > $LOGS

open $LOGS