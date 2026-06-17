import { NestFactory } from '@nestjs/core';
import { TriggerJobModule } from './trigger-job.module';

async function bootstrap() {
  const app = await NestFactory.create(TriggerJobModule);
  await app.listen(process.env.port ?? 3000);
}
bootstrap();
