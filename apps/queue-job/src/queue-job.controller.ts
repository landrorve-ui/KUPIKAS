import { Controller, Get } from '@nestjs/common';
import { QueueJobService } from './queue-job.service';

@Controller()
export class QueueJobController {
  constructor(private readonly queueJobService: QueueJobService) {}

  @Get()
  getHello() {
    return this.queueJobService.getHello();
  }
}
