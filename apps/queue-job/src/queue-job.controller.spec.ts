import { Test, TestingModule } from '@nestjs/testing';
import { QueueJobController } from './queue-job.controller';
import { QueueJobService } from './queue-job.service';

describe('QueueJobController', () => {
  let queueJobController: QueueJobController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [QueueJobController],
      providers: [QueueJobService],
    }).compile();

    queueJobController = app.get<QueueJobController>(QueueJobController);
  });

  describe('root', () => {
    it('should return "Hello World!"', () => {
      expect(queueJobController.healthCheck()).toBe('Hello World!');
    });
  });
});
