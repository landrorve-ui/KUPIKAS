import { Injectable } from '@nestjs/common';
import { PrismaService } from '@sharedb/sharedb';

@Injectable()
export class BackendService {
  constructor(protected prisma: PrismaService) { }

  healthCheck() {
    return {
      status: 'OK',
      version: '1.0.0',
      key: process.env.BACKEND_KEY ?? 'not set',
    }
  }

  users() {
    return this.prisma.userProfile.findMany({});
  }
}
