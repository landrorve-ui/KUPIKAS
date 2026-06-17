import { Injectable } from '@nestjs/common';

@Injectable()
export class TimerService {
  commonTimer() {
    return process.env.TIMER;
  }
}
