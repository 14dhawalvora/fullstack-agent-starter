---
name: observability
description: Add production-style observability to this Spring Boot app - Micrometer metrics (counters, timers, distribution summaries tagged by outcome), structured log lines with request id and latency, and health checks - and show them via /actuator/metrics and logs/backend.log. Use when asked for monitoring, metrics, logging or production readiness.
---

# Observability: metrics, logs, health

Already in place:
- **HTTP latency per endpoint** (automatic): `GET /actuator/metrics/http.server.requests` (filter: `?tag=uri:/api/messages&tag=status:201`).
- **Access log** per API call with request id + status + ms (`RequestIdFilter`), e.g. `INFO [a1b2c3d4] ... POST /api/messages -> 201 (12 ms)`.
- **Health**: `GET /actuator/health` (db + disk).

## Add business metrics (Micrometer)
```java
@Service
public class OrderService {
    private final Counter placed;
    private final Timer placeTimer;
    private final DistributionSummary orderValue;
    private final MeterRegistry registry;

    public OrderService(MeterRegistry registry, ...) {
        this.registry = registry;
        this.placed = Counter.builder("orders.placed").description("Orders placed").register(registry);
        this.placeTimer = Timer.builder("orders.place.latency").publishPercentiles(0.5, 0.95, 0.99).register(registry);
        this.orderValue = DistributionSummary.builder("orders.value").baseUnit("cents").register(registry);
    }

    public OrderResponse place(...) {
        return placeTimer.record(() -> {
            try {
                ...
                placed.increment();
                orderValue.record(amountCents);
                return result;
            } catch (BusinessException e) {
                registry.counter("orders.failed", "reason", e.reason()).increment(); // tag by reason, low cardinality
                throw e;
            }
        });
    }
}
```
Rules:
- Name: `domain.event` (dots). Tags: **low cardinality only** (outcome, reason, type). Never user ids, emails or amounts as tags.
- Count successes AND failures by reason; time the whole business operation; record sizes/values with a DistributionSummary.

## Structured log line per state change
```java
log.info("order.placed id={} customer={} amountCents={} durationMs={}", id, customerId, amount, ms);
log.warn("order.rejected reason={} customer={} amountCents={}", reason, customerId, amount);
```
- key=value pairs so logs can be searched/parsed; the request id is added automatically (MDC).
- INFO for state changes, WARN for rejected business actions, ERROR only for unexpected failures (with stack).
- Never log secrets or full personal data.

## Check it
```bash
curl -s http://localhost:8080/actuator/metrics | grep -o '"orders[^"]*"'
curl -s http://localhost:8080/actuator/metrics/orders.placed
curl -s "http://localhost:8080/actuator/metrics/orders.failed?tag=reason:INVALID"
curl -s http://localhost:8080/actuator/metrics/orders.place.latency
grep "order\." logs/backend.log | tail
```

## Test it
In an integration test, inject `MeterRegistry` and assert the counter moved:
`assertThat(registry.counter("orders.placed").count()).isEqualTo(before + 1);`

## Going further
Prometheus scrape (`micrometer-registry-prometheus`) + Grafana dashboards; alerts on error rate and p99 latency; JSON logs shipped to a log store; tracing (OpenTelemetry) across services.
