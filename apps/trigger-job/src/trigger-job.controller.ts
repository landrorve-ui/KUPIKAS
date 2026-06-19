import { Controller, Get } from '@nestjs/common';
import { TriggerJobService } from './trigger-job.service';

@Controller()
export class TriggerJobController {
  constructor(private readonly triggerJobService: TriggerJobService) {}

  @Get()
  healthCheck() {
    return this.triggerJobService.healthCheck();
  }
}
