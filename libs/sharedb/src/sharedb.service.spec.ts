import { Test, TestingModule } from '@nestjs/testing';
import { SharedbService } from './sharedb.service';

describe('SharedbService', () => {
  let service: SharedbService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [SharedbService],
    }).compile();

    service = module.get<SharedbService>(SharedbService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
