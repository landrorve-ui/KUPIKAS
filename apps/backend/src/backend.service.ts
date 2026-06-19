import { Inject, Injectable, Logger } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { trace, SpanKind, SpanStatusCode } from '@opentelemetry/api';
import { randomUUID } from 'crypto';
import { hostname } from 'os';
import { PrismaService } from '@sharedb/sharedb';
import { JobMessage, injectTraceContext, currentTraceId } from '@lib/telemetry';

const tracer = trace.getTracer('zupikas');

@Injectable()
export class BackendService {
  private readonly logger = new Logger(BackendService.name);

  constructor(
    protected prisma: PrismaService,
    @Inject('NATS_CLIENT') private readonly nats: ClientProxy,
  ) {}

  healthCheck() {
    return {
      status: 'OK',
      version: '1.0.0',
      key: process.env.BACKEND_KEY ?? 'not set',
    };
  }

  users() {
    return this.prisma.userProfile.findMany({});
  }

  async createJob(payload: Record<string, unknown>) {
    return tracer.startActiveSpan(
      'backend.createJob',
      { kind: SpanKind.PRODUCER },
      async (span) => {
        const jobId = randomUUID();
        span.setAttributes({ 'job.id': jobId, 'job.stage': 'backend' });

        const msg: JobMessage = {
          jobId,
          payload,
          metadata: [
            {
              stage: 'backend',
              processedAt: new Date().toISOString(),
              hostname: hostname(),
              durationMs: 0,
            },
          ],
          traceContext: {},
        };

        injectTraceContext(msg);
        this.nats.emit('jobs.queue', msg);

        const traceId = currentTraceId();
        this.logger.log(`Job ${jobId} dispatched → jobs.queue (traceId: ${traceId})`);

        span.setStatus({ code: SpanStatusCode.OK });
        span.end();

        return { jobId, traceId };
      },
    );
  }
}
