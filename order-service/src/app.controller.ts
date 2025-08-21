import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { DaprClient } from '@dapr/dapr';

// Define constants for Dapr pub/sub
const DAPR_PUBSUB_NAME = 'order-pubsub'; // Must match the name in redis-pubsub.yaml
const DAPR_TOPIC_NAME = 'new-orders';

@Controller('orders')
export class AppController {
  private readonly daprClient: DaprClient;

  constructor() {
    // Initialize DaprClient. It will connect to the sidecar.
    this.daprClient = new DaprClient();
    console.log('Order Service: DaprClient initialized.');
  }

  @Post('/create')
  @HttpCode(HttpStatus.ACCEPTED)
  async createOrder(@Body() order: any): Promise<string> {
    console.log(`Order Service: Received request to create order: ${JSON.stringify(order)}`);

    try {
      // Publish the order data to the Dapr topic
      await this.daprClient.pubsub.publish(
        DAPR_PUBSUB_NAME,
        DAPR_TOPIC_NAME,
        order,
      );
      console.log(`Order Service: Successfully published order with ID ${order.orderId} to topic '${DAPR_TOPIC_NAME}'`);

      return `Order ${order.orderId} received and publishing in progress.`;
    } catch (error) {
      console.error('Order Service: Error publishing order:', error);
      
      throw new Error('Failed to publish order event.');
    }
  }
}