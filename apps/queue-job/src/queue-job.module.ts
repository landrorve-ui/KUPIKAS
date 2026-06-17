import { Module } from '@nestjs/common';
import { QueueJobController } from './queue-job.controller';
import { QueueJobService } from './queue-job.service';

@Module({
  imports: [],
  controllers: [QueueJobController],
  providers: [QueueJobService],
})
export class QueueJobModule {}
