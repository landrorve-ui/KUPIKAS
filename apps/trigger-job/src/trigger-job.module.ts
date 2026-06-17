import { Module } from '@nestjs/common';
import { TriggerJobController } from './trigger-job.controller';
import { TriggerJobService } from './trigger-job.service';

@Module({
  imports: [],
  controllers: [TriggerJobController],
  providers: [TriggerJobService],
})
export class TriggerJobModule {}
