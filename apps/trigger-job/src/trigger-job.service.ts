import { Injectable } from '@nestjs/common';

@Injectable()
export class TriggerJobService {
  healthCheck() {
    return {
      status: 'OK',
      key: process.env.TRIGGER_JOB_KEY,
    }
  }
}
