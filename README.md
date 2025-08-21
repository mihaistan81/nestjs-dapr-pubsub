<p align="center">
  <a href="http://nestjs.com/" target="blank"><img src="https://nestjs.com/img/logo-small.svg" width="120" alt="Nest Logo" /></a>
</p>

[circleci-image]: https://img.shields.io/circleci/build/github/nestjs/nest/master?token=abc123def456
[circleci-url]: https://circleci.com/gh/nestjs/nest

  <p align="center">A progressive <a href="http://nodejs.org" target="_blank">Node.js</a> framework for building efficient and scalable server-side applications.</p>


## Steps to configure & run LOCALLY with docker-compose.yml

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




## Steps to Run LOCALLY Dapr components - Manually


Start Redis (Message Broker)

```bash
docker run --name dapr-pubsub-redis -p 6379:6379 -d redis/redis:6-alpine
```

Run the Shipping Service (Subscriber) with Dapr
Open a new terminal and run the Shipping Service with its Dapr sidecar.
```bash
$ dapr run --app-id shipping-service --app-port 3001 --dapr-http-port 3501 --resources-path ./components -- nest start --prefix shipping-service
```

Run the Order Service (Publisher) with Dapr
Open another terminal and run the Order Service.
```bash
$ dapr run --app-id order-service --app-port 3000 --dapr-http-port 3500 --resources-path ./components -- nest start --prefix order-service
```
