import { initTracing } from '@lib/telemetry';
initTracing('trigger-job');

import { NestFactory } from '@nestjs/core';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { TriggerJobModule } from './trigger-job.module';

async function bootstrap() {
  const app = await NestFactory.create(TriggerJobModule);

  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.NATS,
    options: {
      servers: [process.env.NATS_URL ?? 'nats://nats:4222'],
    },
  });

  await app.startAllMicroservices();
  await app.listen(3335);
}
bootstrap();
