import { NestFactory } from '@nestjs/core';
import { TriggerJobModule } from './trigger-job.module';

async function bootstrap() {
  const app = await NestFactory.create(TriggerJobModule);
  await app.listen(3335);
}
bootstrap();
