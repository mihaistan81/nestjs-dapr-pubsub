#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(dirname "$(realpath "$0")")

# ==== CONFIG ====
RESOURCE_GROUP=${RESOURCE_GROUP:-nestjs-dapr-rg}
LOCATION=${LOCATION:-eastus2}
ACR_NAME="dapracr24996" # ${ACR_NAME:-dapracr$RANDOM}
ENVIRONMENT=${ENVIRONMENT:-nestjs-dapr-env}
REDIS_NAME=${REDIS_NAME:-nestjsdaprredis}
ORDER_SERVICE_APP=${ORDER_SERVICE_APP:-order-service}
SHIPPING_SERVICE_APP=${SHIPPING_SERVICE_APP:-shipping-service}

echo "RESOURCE GROUP: $RESOURCE_GROUP"
echo "LOCATION: $LOCATION"
echo "ACR_NAME: $ACR_NAME"
echo "ENVIRONMENT: $ENVIRONMENT"
echo "REDIS_NAME: $REDIS_NAME"
echo "ORDER_SERVICE_APP: $ORDER_SERVICE_APP"
echo "SHIPPING_SERVICE_APP: $SHIPPING_SERVICE_APP"

echo "Install the Azure CLI extension for Container Apps:"
az extension add --name containerapp --upgrade --allow-preview true

# Register the namespaces
echo "Register the namespaces"
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights

# Create resource group
echo "Create resource group"
az group create -n "$RESOURCE_GROUP" -l "$LOCATION" -o table

echo "Create ACR_NAME"
az acr create -n "$ACR_NAME" -g "$RESOURCE_GROUP" --sku Basic


# Build and Push the order-service Image
echo "Build and Push the order-service Image"
az acr build \
  --registry $ACR_NAME \
  --image order-service:v1 \
  --resource-group $RESOURCE_GROUP \
  --file ./order-service/Dockerfile \
  ./order-service

# Build and Push the shipping-service Image
echo "Build and Push the shipping-service Image"
az acr build \
  --registry $ACR_NAME \
  --image shipping-service:v1 \
  --resource-group $RESOURCE_GROUP \
  --file ./shipping-service/Dockerfile \
  ./shipping-service


# Create a Log Analytics workspace and get the workspace ID and primary key
echo "Create a Log Analytics workspace and get the workspace ID and primary key"
LOG_ANALYTICS_NAME=${LOG_ANALYTICS_NAME:-dapr-workspace}

az monitor log-analytics workspace create \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $LOG_ANALYTICS_NAME \
  --location $LOCATION

# Get the workspace ID
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $LOG_ANALYTICS_NAME \
  --query customerId \
  --output tsv)

# Get the primary key
WORKSPACE_KEY=$(az monitor log-analytics workspace get-shared-keys \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $LOG_ANALYTICS_NAME \
  --query primarySharedKey \
  --output tsv)

echo "Log Analytics Workspace ID: $WORKSPACE_ID"
echo "Log Analytics Primary Key: $WORKSPACE_KEY"

# Create a Container Apps environment
az containerapp env create -g "$RESOURCE_GROUP" -n "$ENVIRONMENT" -l "$LOCATION" --logs-workspace-id "$WORKSPACE_ID" --logs-workspace-key "$WORKSPACE_KEY"

REDIS_NAME="dapr-redis-32746" # "dapr-redis-$RANDOM"
REDIS_SKU="Basic"
REDIS_SIZE="C1"

# Create the Redis instance
az redis create \
  --name $REDIS_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku $REDIS_SKU \
  --vm-size $REDIS_SIZE

# Get the Redis access key 
# REDIS_KEY=$(az redis list-keys --name $REDIS_NAME --resource-group $RESOURCE_GROUP --query primaryKey --output tsv)
echo "Retrieving Redis primary key..."
REDIS_KEY=$(az redis list-keys \
  --name $REDIS_NAME \
  --resource-group $RESOURCE_GROUP \
  --query primaryKey \
  --output tsv)

# Get Redis hostname (endpoint)
REDIS_HOSTNAME=$(az redis show \
  --name $REDIS_NAME \
  --resource-group $RESOURCE_GROUP \
  --query hostName \
  --output tsv)

# # Create the secret in my Container Apps Environment
# # This command stores my Redis key under the name 'redis-password'
# echo "Creating secret 'redis-password' in the environment..."
# az containerapp secret set \
#   --resource-group $RESOURCE_GROUP \
#   --name $ENVIRONMENT \
#   --secrets "redis-password=$REDIS_KEY"

echo "Redis Name: $REDIS_NAME"
echo "Redis Hostname: $REDIS_HOSTNAME"
echo "Redis Key: $REDIS_KEY" # DAVzPDLhxJR5GzRupz5klSOnu4Rgt1dVoAzCaCFnOow=

# --- Create Dapr Pub/Sub Component ---
echo "Creating Dapr pub/sub component 'order-pubsub' for Redis..."
DAPR_PUBSUB_COMPONENT_NAME="order-pubsub"

az containerapp env dapr-component set \
  --name $ENVIRONMENT \
  --resource-group $RESOURCE_GROUP \
  --dapr-component-name $DAPR_PUBSUB_COMPONENT_NAME \
  --yaml "./components/dapr-pubsub-component.yaml" \
#   --component-type "pubsub.redis" \
#   --version "v1" \
#   --secret "redis-password=$REDIS_KEY" \
#   --metadata "redisHost=$REDIS_HOSTNAME:6379" "redisPassword=redis-password" "enableTLS=true"

echo "Logging in to Azure Container Registry..."
az acr login --name $ACR_NAME --expose-token

ORDER_SERVICE_IMAGE=$ACR_NAME.azurecr.io/order-service:v1
SHIPPING_SERVICE_IMAGE=$ACR_NAME.azurecr.io/shipping-service:v1

echo "Order Service Image: $ORDER_SERVICE_IMAGE"
echo "Shipping Service Image: $SHIPPING_SERVICE_IMAGE"

# --- Deploy Order Service (Publisher) ---
echo "Deploying Order Service container app..."
az containerapp create \
  --name $ORDER_SERVICE_APP \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT \
  --image $ORDER_SERVICE_IMAGE \
  --target-port 3000 \
  --registry-server $ACR_NAME.azurecr.io \
  --ingress external \
  --enable-dapr \
  --dapr-app-id $ORDER_SERVICE_APP \
  --dapr-app-port 3000 \
#   --min-replicas 1 \
  --query "properties.configuration.ingress.fqdn" \
  --output tsv

# --- Deploy Shipping Service (Subscriber) ---
echo "Deploying Shipping Service container app..."
az containerapp create \
  --name $SHIPPING_SERVICE_APP \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT \
  --image $SHIPPING_SERVICE_IMAGE \
  --target-port 3001 \
  --registry-server $ACR_NAME.azurecr.io \
  --ingress internal \
  --enable-dapr \
  --dapr-app-id $SHIPPING_SERVICE_APP \
  --dapr-app-port 3001 \
  --min-replicas 1

echo "Checking the subscriber logs:"
echo "    az containerapp logs show -g $RESOURCE_GROUP -n $SHIPPING_SERVICE_APP --follow --type console"
