import { Controller, Get } from '@nestjs/common';
import { Ctx, MessagePattern, NatsContext, Payload } from '@nestjs/microservices';
import { QueueJobService } from './queue-job.service';
import { JobMessage } from '@lib/telemetry';

@Controller()
export class QueueJobController {
  constructor(private readonly queueJobService: QueueJobService) {}

  @Get()
  healthCheck() {
    return this.queueJobService.healthCheck();
  }

  @MessagePattern('jobs.queue')
  handleJob(@Payload() msg: JobMessage, @Ctx() _ctx: NatsContext) {
    return this.queueJobService.process(msg);
  }
}
