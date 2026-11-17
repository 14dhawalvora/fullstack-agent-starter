# API contract

Base path `/api`. JSON in/out.
Errors are problem JSON: `{"status":400,"detail":"Validation failed","errors":{"content":"must not be blank"},"requestId":"a1b2c3d4"}`.

| Method | Path | Request | Success | Errors |
|---|---|---|---|---|
| GET | /messages/latest?limit=10 | limit 1-100 | 200 `Message[]` newest first | - |
| POST | /messages | `{content (1-500 chars)}` | 201 `Message` | 400 |
| GET | /ping | - | 200 `{status: "ok"}` (used by verify) | - |

Health: `GET /actuator/health`. Metrics: `GET /actuator/metrics`, `GET /actuator/metrics/{name}`.

## Types
```ts
Message { id: number; content: string; createdAt: string /* ISO-8601 */ }
```

## New features
Add rows here first (method, path, request, success, errors), agree, then build backend and frontend in parallel.
