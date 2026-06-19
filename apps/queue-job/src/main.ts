import { initTracing } from '@lib/telemetry';
initTracing('queue-job');

import { NestFactory } from '@nestjs/core';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { QueueJobModule } from './queue-job.module';

async function bootstrap() {
  const app = await NestFactory.create(QueueJobModule);

  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.NATS,
    options: {
      servers: [process.env.NATS_URL ?? 'nats://nats:4222'],
    },
  });

  await app.startAllMicroservices();
  await app.listen(3334);
}
bootstrap();
