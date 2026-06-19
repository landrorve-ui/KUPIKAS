import {
  context,
  propagation,
  trace,
  SpanKind,
  SpanStatusCode,
  Span,
} from '@opentelemetry/api';
import type { JobMessage } from './job-message';

const tracer = () => trace.getTracer('zupikas');

export function injectTraceContext(msg: JobMessage): void {
  const carrier: Record<string, string> = {};
  propagation.inject(context.active(), carrier);
  msg.traceContext = carrier;
}

export async function runInJobSpan<T>(
  msg: JobMessage,
  spanName: string,
  fn: (span: Span) => Promise<T>,
): Promise<T> {
  const parentCtx = propagation.extract(context.active(), msg.traceContext ?? {});
  return context.with(parentCtx, () =>
    tracer().startActiveSpan(
      spanName,
      { kind: SpanKind.CONSUMER, attributes: { 'job.id': msg.jobId } },
      async (span) => {
        try {
          const result = await fn(span);
          span.setStatus({ code: SpanStatusCode.OK });
          return result;
        } catch (err) {
          span.recordException(err as Error);
          span.setStatus({ code: SpanStatusCode.ERROR, message: (err as Error).message });
          throw err;
        } finally {
          span.end();
        }
      },
    ),
  );
}

export function currentTraceId(): string {
  return trace.getActiveSpan()?.spanContext().traceId ?? '';
}
