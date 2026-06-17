import { Injectable } from '@nestjs/common';

@Injectable()
export class TriggerJobService {
  getHello() {
    return {
      status: 'OK',
      key: process.env.TRIGGER_JOB_KEY,
    }
  }
}
