import { Module } from '@nestjs/common';
import { SharedbService } from './sharedb.service';
import { PrismaService } from './prisma.service';

@Module({
  providers: [PrismaService, SharedbService],
  exports: [PrismaService, SharedbService],
})
export class SharedbModule {}
