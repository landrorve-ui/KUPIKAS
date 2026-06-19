import { Body, Controller, Get, Post } from '@nestjs/common';
import { BackendService } from './backend.service';

@Controller()
export class BackendController {
  constructor(private readonly backendService: BackendService) {}

  @Get()
  healthCheck() {
    return this.backendService.healthCheck();
  }

  @Get('users')
  getUsers() {
    return this.backendService.users();
  }

  @Post('jobs')
  createJob(@Body() payload: Record<string, unknown>) {
    return this.backendService.createJob(payload);
  }
}
