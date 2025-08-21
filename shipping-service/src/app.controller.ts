import { Controller, Post, Get, Body, HttpCode, HttpStatus } from '@nestjs/common';

const DAPR_PUBSUB_NAME = 'order-pubsub';
const DAPR_TOPIC_NAME = 'new-orders';

@Controller()
export class AppController {

  // This endpoint is for Dapr to discover the subscriptions of this service.
  // Dapr will call it on startup to get the list of topics to subscribe to.
  @Get('/dapr/subscribe')
  getDaprSubscriptions() {
    console.log('Shipping Service: Responding to Dapr subscription request.');
    return [
      {
        pubsubname: DAPR_PUBSUB_NAME,
        topic: DAPR_TOPIC_NAME,
        route: '/new-order'
      }
    ];
  }
  
  // This is the actual endpoint that receives the message from Dapr.
  // The route matches the one specified in the getDaprSubscriptions method.
  @Post('/new-order')
  @HttpCode(HttpStatus.OK)
  handleNewOrder(@Body() event: any): void {
    console.log(`EVENT Received: ${JSON.stringify(event)}`);

    const order = event.data; // Dapr sends the payload inside a 'event.data' field.
    console.log(`Shipping Service: Received new order event for: ${order.item}`);
    
    console.log(`Shipping Service: Processing order ID: ${order.orderId}`);
  }
}