import { Controller, Get, Inject } from '@nestjs/common';
import { HealthService } from './health.service';

@Controller()
export class HealthController {
    constructor(private readonly appService: HealthService) { }

    @Get('/health')
    getHealth(): string {
        return this.appService.checkHealth();
    }

    @Get('/liveness')
    getLiveness(): string {
        return this.appService.checkLiveness();
    }
}
