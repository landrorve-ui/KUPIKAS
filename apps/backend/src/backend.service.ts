import { Injectable } from '@nestjs/common';

@Injectable()
export class BackendService {
  getHello() {
    return {
      status:  'OK',
      key:     process.env.BACKEND_KEY,
    }
  }
}
