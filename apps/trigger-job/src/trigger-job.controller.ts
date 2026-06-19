import { Controller, Get } from '@nestjs/common';
import { Ctx, MessagePattern, NatsContext, Payload } from '@nestjs/microservices';
import { TriggerJobService } from './trigger-job.service';
import { JobMessage } from '@lib/telemetry';

@Controller()
export class TriggerJobController {
  constructor(private readonly triggerJobService: TriggerJobService) {}

  @Get()
  healthCheck() {
    return this.triggerJobService.healthCheck();
  }

  @MessagePattern('jobs.trigger')
  handleJob(@Payload() msg: JobMessage, @Ctx() _ctx: NatsContext) {
    return this.triggerJobService.process(msg);
  }
}
