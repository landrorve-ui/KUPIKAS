import { NestFactory } from '@nestjs/core';
import { QueueJobModule } from './queue-job.module';

async function bootstrap() {
  const app = await NestFactory.create(QueueJobModule);
  await app.listen(process.env.port ?? 3000);
}
bootstrap();
