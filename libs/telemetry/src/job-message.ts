export type JobStage = 'backend' | 'queue-job' | 'trigger-job';

export interface JobMetadata {
  stage: JobStage;
  processedAt: string;
  hostname: string;
  durationMs: number;
}

export interface JobMessage {
  jobId: string;
  payload: Record<string, unknown>;
  metadata: JobMetadata[];
  traceContext: Record<string, string>;
}
