import { Injectable, Logger } from '@nestjs/common';
import { hostname } from 'os';
import { JobMessage, runInJobSpan } from '@lib/telemetry';

@Injectable()
export class TriggerJobService {
  private readonly logger = new Logger(TriggerJobService.name);

  healthCheck() {
    return { status: 'OK', key: process.env.TRIGGER_JOB_KEY };
  }

  async process(msg: JobMessage): Promise<void> {
    await runInJobSpan(msg, 'trigger-job.process', async (span) => {
      const originatedAt = new Date(msg.metadata[0].processedAt).getTime();
      const totalMs = Date.now() - originatedAt;

      const final: JobMessage = {
        ...msg,
        payload: {
          ...msg.payload,
          triggeredAt: new Date().toISOString(),
        },
        metadata: [
          ...msg.metadata,
          {
            stage: 'trigger-job',
            processedAt: new Date().toISOString(),
            hostname: hostname(),
            durationMs: totalMs,
          },
        ],
        traceContext: {},
      };

      span.setAttributes({
        'job.total_duration_ms': totalMs,
        'job.stages_completed': final.metadata.length,
        'job.trigger.hostname': hostname(),
      });

      this.logger.log(
        `Job ${msg.jobId} COMPLETED — ${final.metadata.length} stages, ${totalMs}ms total\n` +
          JSON.stringify(final.metadata, null, 2),
      );
    });
  }
}
