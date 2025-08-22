import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { json } from 'express';

async function bootstrap() {
  // Use createApplicationContext for microservices if you don't need a full HTTP server,
  // or create a regular app and tell Dapr the HTTP port for subscriptions.
  const app = await NestFactory.create(AppModule);

  app.use(json({ type: 'application/cloudevents+json' }));

  // Ensure the application listens on the port defined in DaprModule.register()
  const port = 3000; // This port should be consistent with DaprModule.register and Dapr run command
  await app.listen(port);
  console.log(`Shipping Service is running on http://localhost:${port} and listening for Dapr messages.`);
}
bootstrap();

