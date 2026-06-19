import { Inject, Injectable, Logger } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { hostname } from 'os';
import { JobMessage, injectTraceContext, runInJobSpan } from '@lib/telemetry';

@Injectable()
export class QueueJobService {
  private readonly logger = new Logger(QueueJobService.name);

  constructor(@Inject('NATS_CLIENT') private readonly nats: ClientProxy) {}

  healthCheck() {
    return { status: 'OK', key: process.env.QUEUE_JOB_KEY };
  }

  async process(msg: JobMessage): Promise<void> {
    await runInJobSpan(msg, 'queue-job.process', async (span) => {
      const startedAt = Date.now();

      const enriched: JobMessage = {
        ...msg,
        payload: {
          ...msg.payload,
          queuedAt: new Date().toISOString(),
        },
        metadata: [
          ...msg.metadata,
          {
            stage: 'queue-job',
            processedAt: new Date().toISOString(),
            hostname: hostname(),
            durationMs: Date.now() - startedAt,
          },
        ],
        traceContext: {},
      };

      span.setAttributes({
        'job.queue.hostname': hostname(),
        'job.metadata.count': enriched.metadata.length,
      });

      injectTraceContext(enriched);
      this.nats.emit('jobs.trigger', enriched);

      this.logger.log(`Job ${msg.jobId} enriched → jobs.trigger`);
    });
  }
}
