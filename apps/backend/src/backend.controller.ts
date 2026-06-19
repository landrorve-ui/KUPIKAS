import { Controller, Get } from '@nestjs/common';
import { BackendService } from './backend.service';

@Controller()
export class BackendController {
  constructor(private readonly backendService: BackendService) { }

  @Get()
  healthCheck() {
    return this.backendService.healthCheck();
  }
  @Get('users')
  getUsers() {
    return this.backendService.users();
  }
}
