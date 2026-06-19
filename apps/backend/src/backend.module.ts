import { Module } from '@nestjs/common';
import { BackendController } from './backend.controller';
import { BackendService } from './backend.service';
import { SharedbModule } from '@sharedb/sharedb/sharedb.module';

@Module({
  imports: [SharedbModule],
  controllers: [BackendController],
  providers: [BackendService],
})
export class BackendModule {}
