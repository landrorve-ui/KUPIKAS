import { Module } from '@nestjs/common';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { BackendController } from './backend.controller';
import { BackendService } from './backend.service';
import { SharedbModule } from '@sharedb/sharedb/sharedb.module';

@Module({
  imports: [
    SharedbModule,
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
  controllers: [BackendController],
  providers: [BackendService],
})
export class BackendModule {}
