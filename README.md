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
   scripts/deploy.sh    # build, push & deploy script
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





