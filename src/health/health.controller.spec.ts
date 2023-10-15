import { Test, TestingModule } from '@nestjs/testing';
import { HealthController } from './health.controller';
import { HealthService } from './health.service';

describe('HealthController', () => {
  let healthController: HealthController;

  beforeEach(async () => {
    const health: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [HealthService],
    }).compile();

    healthController = health.get<HealthController>(HealthController);
  });

  describe('health check', () => {
    it('should return Ok', () => {
      expect(healthController.getHealth()).toBe('Health OK');
    });
  });

  describe('liveness check', () => {
    it('should return Ok', () => {
      expect(healthController.getLiveness()).toBe('Liveness OK');
    });
  });
});
