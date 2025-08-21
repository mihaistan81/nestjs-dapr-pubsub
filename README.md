<p align="center">
  <a href="http://nestjs.com/" target="blank"><img src="https://nestjs.com/img/logo-small.svg" width="120" alt="Nest Logo" /></a>
</p>

[circleci-image]: https://img.shields.io/circleci/build/github/nestjs/nest/master?token=abc123def456
[circleci-url]: https://circleci.com/gh/nestjs/nest

  <p align="center">A progressive <a href="http://nodejs.org" target="_blank">Node.js</a> framework for building efficient and scalable server-side applications.</p>
## Description

[Nest](https://github.com/nestjs/nest) framework TypeScript starter repository.

## Project setup

```bash
$ npm install
```

## Compile and run the project

```bash
# development
$ npm run start

# watch mode
$ npm run start:dev

# production mode
$ npm run start:prod
```

## Deployment

When you're ready to deploy your NestJS application to production, there are some key steps you can take to ensure it runs as efficiently as possible. Check out the [deployment documentation](https://docs.nestjs.com/deployment) for more information.

If you are looking for a cloud-based platform to deploy your NestJS application, check out [Mau](https://mau.nestjs.com), our official platform for deploying NestJS applications on AWS. Mau makes deployment straightforward and fast, requiring just a few simple steps:

```bash
$ npm install -g @nestjs/mau
$ mau deploy
```

With Mau, you can deploy your application in just a few clicks, allowing you to focus on building features rather than managing infrastructure.


## Steps

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

Test the Communication
Send a request to the Order Service to trigger the pub/sub flow.

```bash
$ curl -X POST -H "Content-Type: application/json" -d '{"orderId": "333", "item": "Laptop", "quantity": 6}' http://localhost:3500/v1.0/invoke/order-service/method/orders/create
```

Monitor the REDIS messages on the QUEUES
```bash
$ winpty docker exec -it dapr-pubsub-redis redis-cli
```
And then type MONITOR

Docker Compose commands: 
```bash
$ docker-compose up --build -d
$ docker-compose down
$ docker-compose logs -f
```

Docker Clean Up commands: 
```bash
docker stop order-service shipping-service dapr-order-sidecar dapr-shipping-sidecar dapr-pubsub-redis zipkin
docker rm order-service shipping-service dapr-order-sidecar dapr-shipping-sidecar dapr-pubsub-redis zipkin
```