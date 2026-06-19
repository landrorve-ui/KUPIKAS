import { Test, TestingModule } from '@nestjs/testing';
import { TriggerJobController } from './trigger-job.controller';
import { TriggerJobService } from './trigger-job.service';

describe('TriggerJobController', () => {
  let triggerJobController: TriggerJobController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [TriggerJobController],
      providers: [TriggerJobService],
    }).compile();

    triggerJobController = app.get<TriggerJobController>(TriggerJobController);
  });

  describe('root', () => {
    it('should return "Hello World!"', () => {
      expect(triggerJobController.healthCheck()).toBe('Hello World!');
    });
  });
});
