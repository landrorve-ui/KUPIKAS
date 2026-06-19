import { Injectable } from '@nestjs/common';

@Injectable()
export class QueueJobService {
  healthCheck() {
    return {
      status: 'OK',
      key: process.env.QUEUE_JOB_KEY,
    }
  }
}
