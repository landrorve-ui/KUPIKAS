#!/usr/bin/env bash
# End-to-end test of the full job pipeline + monitoring stack.
# Usage: ./scripts/test-flow.sh [BACKEND_URL] [TEMPO_URL] [PROMETHEUS_URL]
#
# Defaults assume you have kubectl port-forwards running:
#   kubectl port-forward -n zupikas svc/backend 3333:3333
#   kubectl port-forward -n monitoring svc/tempo 3100:3100
#   kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

set -euo pipefail

BACKEND_URL="${1:-http://localhost:3333}"
TEMPO_URL="${2:-http://localhost:3100}"
PROM_URL="${3:-http://localhost:9090}"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}✓ $1${NC}"; }
fail() { echo -e "${RED}✗ $1${NC}"; exit 1; }
info() { echo -e "${YELLOW}→ $1${NC}"; }

# ── 1. Health checks ─────────────────────────────────────────────────────────
info "Checking service health..."

curl -sf "$BACKEND_URL" | grep -q '"status":"OK"' && pass "backend healthy" || fail "backend not healthy"

# ── 2. Submit a job ───────────────────────────────────────────────────────────
info "Submitting job to backend..."

RESPONSE=$(curl -sf -X POST "$BACKEND_URL/jobs" \
  -H "Content-Type: application/json" \
  -d '{"name":"smoke-test","data":{"foo":"bar","timestamp":"'"$(date -u +%FT%TZ)"'"}}')

echo "Response: $RESPONSE"

JOB_ID=$(echo "$RESPONSE" | jq -r '.jobId')
TRACE_ID=$(echo "$RESPONSE" | jq -r '.traceId')

[[ "$JOB_ID" != "null" && -n "$JOB_ID" ]]   && pass "jobId received: $JOB_ID"   || fail "no jobId in response"
[[ "$TRACE_ID" != "null" && -n "$TRACE_ID" ]] && pass "traceId received: $TRACE_ID" || fail "no traceId in response"

# ── 3. Wait for pipeline to complete (NATS is async) ─────────────────────────
info "Waiting 5s for NATS pipeline (backend→queue-job→trigger-job)..."
sleep 5

# ── 4. Verify trace in Tempo ─────────────────────────────────────────────────
info "Querying Tempo for trace $TRACE_ID..."

TRACE_RESPONSE=$(curl -sf "$TEMPO_URL/api/traces/$TRACE_ID" || echo "")

if [[ -z "$TRACE_RESPONSE" ]]; then
  fail "Tempo returned empty response — trace may not have flushed yet (increase sleep or check OTel Collector)"
fi

SPAN_COUNT=$(echo "$TRACE_RESPONSE" | jq '[.batches[].scopeSpans[].spans[]] | length' 2>/dev/null || echo "0")
info "Spans found in Tempo: $SPAN_COUNT"

[[ "$SPAN_COUNT" -ge 3 ]] && pass "All 3 pipeline spans visible in Tempo (backend + queue-job + trigger-job)" \
  || fail "Expected ≥3 spans, got $SPAN_COUNT — check OTel Collector and Tempo logs"

SERVICE_NAMES=$(echo "$TRACE_RESPONSE" | jq -r '
  [.batches[].resource.attributes[]
    | select(.key=="service.name")
    | .value.stringValue]
  | unique | sort | join(", ")' 2>/dev/null || echo "unknown")
pass "Services in trace: $SERVICE_NAMES"

# ── 5. Verify Prometheus scraping metrics ─────────────────────────────────────
info "Querying Prometheus for HTTP server metrics..."

PROM_QUERY='http_server_duration_milliseconds_count{service_name="backend"}'
PROM_RESULT=$(curl -sf "$PROM_URL/api/v1/query" \
  --data-urlencode "query=$PROM_QUERY" | jq '.data.result | length')

[[ "$PROM_RESULT" -gt 0 ]] \
  && pass "Prometheus has ${PROM_RESULT} time series for backend HTTP metrics" \
  || fail "No Prometheus metrics for backend — check OTel Collector prometheusremotewrite exporter"

# ── 6. Check Alertmanager is reachable ────────────────────────────────────────
ALERTMANAGER_URL="${PROM_URL/9090/9093}"
STATUS=$(curl -sf "$ALERTMANAGER_URL/api/v2/status" | jq -r '.status.cluster.status' 2>/dev/null || echo "unreachable")
[[ "$STATUS" == "ready" || "$STATUS" == "disabled" ]] \
  && pass "Alertmanager status: $STATUS" \
  || info "Alertmanager not reachable at $ALERTMANAGER_URL (port-forward svc/kube-prometheus-stack-alertmanager 9093:9093)"

# ── 7. Trigger an alert by simulating high error rate ────────────────────────
info "Sending 10 bad requests to trigger 5xx alert rule..."
for i in $(seq 1 10); do
  curl -sf -X POST "$BACKEND_URL/nonexistent-endpoint-to-force-404" \
    -H "Content-Type: application/json" -d '{}' >/dev/null 2>&1 || true
done
pass "Sent error requests — check Alertmanager UI for firing alerts after ~1 minute"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}All checks passed!${NC}"
echo ""
echo "  Job ID  : $JOB_ID"
echo "  Trace ID: $TRACE_ID"
echo ""
echo "  Grafana   → http://localhost:3000  (port-forward svc/kube-prometheus-stack-grafana 3000:80)"
echo "  Explore → Tempo → Trace ID: $TRACE_ID"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
