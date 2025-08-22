<p align="center">
  <a href="http://nestjs.com/" target="blank"><img src="https://nestjs.com/img/logo-small.svg" width="120" alt="Nest Logo" /></a>
</p>

[circleci-image]: https://img.shields.io/circleci/build/github/nestjs/nest/master?token=abc123def456
[circleci-url]: https://circleci.com/gh/nestjs/nest

  <p align="center">A progressive <a href="http://nodejs.org" target="_blank">Node.js</a> framework for building efficient and scalable server-side applications.</p>


## Project structure:
```
   order-service/       # NestJs service
   shipping-service/    # NestJs service
   components/
      dapr-pubsub-component.yaml
      redis-pubsub.yml  # Redis PubSub
      config-tracing.yaml # ZipKin config for distributed tracing
      resiliency.yaml   # Retry forever and circuit breaker
   scripts/
      deploy.sh         # build, push & deploy script
   docker-compose.yml   # For running the containers Locally 
   package-lock.json
   package.json
   README.md
```

## 1. Steps to Run project in Cloud with ACA Dapr components 

Login to Azure 
```bash
az login
```

Run the deploy script
```bash
bash script/deploy.sh
```

### Results from the deployment run
Container app created. Access your app at https://order-service.ashyriver-741d3c87.eastus2.azurecontainerapps.io/

Container app created. Access your app at https://shipping-service.internal.ashyriver-741d3c87.eastus2.azurecontainerapps.io/

shipping-service.internal.ashyriver-741d3c87.eastus2.azurecontainerapps.io
Checking the subscriber logs:
    az containerapp logs show -g nestjs-dapr-rg -n shipping-service --follow --type console

curl -X POST -H "Content-Type: application/json" -d '{"orderId": "333", "item": "Laptop", "quantity": 6}' https://order-service.ashyriver-741d3c87.eastus2.azurecontainerapps.io/v1.0/invoke/order-service/method/orders/create



## 2. Steps to configure & run LOCALLY with docker-compose.yml

Docker Compose command to build & run the containers: 
```bash
$ docker-compose up --build -d
```

Monitor the REDIS messages on the QUEUES
```bash
$ winpty docker exec -it dapr-pubsub-redis redis-cli
```
And then type MONITOR

Test the Communication
Send a request to the Order Service to trigger the pub/sub flow.

```bash
$ curl -X POST -H "Content-Type: application/json" -d '{"orderId": "333", "item": "Laptop", "quantity": 6}' http://localhost:3500/v1.0/invoke/order-service/method/orders/create
```

Docker Compose commands to see the containers LOGS: 
```bash
$ docker-compose logs -f
```

Docker Compose commands to put down the containers: 
```bash
$ docker-compose down
```

Docker Clean Up commands: 
```bash
docker stop order-service shipping-service dapr-order-sidecar dapr-shipping-sidecar dapr-pubsub-redis zipkin
docker rm order-service shipping-service dapr-order-sidecar dapr-shipping-sidecar dapr-pubsub-redis zipkin
```




## Problems during ACA deployment, where AI helped: 

### 1) Problem
```
Code: RequestDisallowedByPolicy
Message: Resource 'dapr-redis-32746' was disallowed by policy. Policy identifiers: '[{"policyAssignment":{"name":"AzureB2C","id":"/subscriptions/68674729-bf3f-4318-9737-2752e8d55809/providers/Microsoft.Authorization/policyAssignments/3b46d691-4ad0-43f1-863c-89191fa86395"},"policyDefinition":{"name":"AzureB2C_denyHDInsightPolicy","id":"/subscriptions/68674729-bf3f-4318-9737-2752e8d55809/providers/Microsoft.Authorization/policyDefinitions/AzureB2C_denyHDInsightPolicy","version":"1.0.0"},"policySetDefinition":{"name":"AzureB2C","id":"/subscriptions/68674729-bf3f-4318-9737-2752e8d55809/providers/Microsoft.Authorization/policySetDefinitions/AzureB2C","version":"1.0.0"}}]'.
Target: dapr-redis-32746
Additional Information:Type: PolicyViolation
```

** AI response: **
```
This error message means that an Azure Policy in your subscription is preventing you from creating an Azure Cache for Redis instance. The policy is named AzureB2C_denyHDInsightPolicy, but it's incorrectly configured to also block the Redis resource type.

You cannot bypass an Azure Policy with a CLI command. The definitive solution is to have an Azure administrator for your subscription either:

Remove the policy assignment that is blocking the resource.

Modify the policy definition to exclude Azure Cache for Redis.

If you are unable to get the policy changed, the only workaround is to use a different resource that is not disallowed by the policy. A great alternative is Azure Cosmos DB for Redis, which provides a managed Redis API that Dapr can connect to.

If you would like the updated commands to use Azure Cosmos DB, please let me know.
```
