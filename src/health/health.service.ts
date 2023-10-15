import { Injectable } from '@nestjs/common';

@Injectable()
export class HealthService {
    checkHealth(): string {
        return 'Health OK';
    }

    checkLiveness(): string {
        return 'Liveness OK'
    }
}
