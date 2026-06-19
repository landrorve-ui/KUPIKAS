import { Module } from '@nestjs/common';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { QueueJobController } from './queue-job.controller';
import { QueueJobService } from './queue-job.service';

@Module({
  imports: [
    ClientsModule.register([
      {
        name: 'NATS_CLIENT',
        transport: Transport.NATS,
        options: {
          servers: [process.env.NATS_URL ?? 'nats://nats:4222'],
        },
      },
    ]),
  ],
  controllers: [QueueJobController],
  providers: [QueueJobService],
})
export class QueueJobModule {}
