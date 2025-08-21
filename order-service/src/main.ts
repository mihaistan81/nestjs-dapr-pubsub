import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  // Listen on a specific port for incoming HTTP requests
  const port = 3000;
  await app.listen(port);
  console.log(`Order Service is running on http://localhost:${port}`);
}
bootstrap();
