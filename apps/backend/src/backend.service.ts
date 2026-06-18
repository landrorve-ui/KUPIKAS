import { Injectable } from '@nestjs/common';

@Injectable()
export class BackendService {
  getHello() {
    return {
      status:  'OK',
      version: '1.0.0',
      key:     process.env.BACKEND_KEY ?? 'not set',
    }
  }
}
