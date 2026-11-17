# Project guide for coding agents

Full-stack starter: **Spring Boot 3 (Java 21) + H2 (Postgres mode, Flyway) + React 18 (TypeScript, Vite)**. Runs natively on Windows, no Docker.
Sample feature: a message board (`messages`). New features copy its shape.

## Environment
- Windows, Git Bash shell. No Docker. Prereqs: JDK 21, Maven, Node 18+.
- Ports: dev 8080 (backend) + 5173 (frontend); e2e stack 8081 + 5174 (started and stopped by Playwright).
- Always use `./dev.sh`, `./verify.sh`, `./diagnose.sh`. Running a `.ps1` directly can fail (Windows execution policy); the wrappers bypass it.
- `./dev.sh` starts the servers detached, so the command returns; stop them with `./dev.sh -Stop`.

## Map
```
backend/   Spring Boot REST API on :8080
  src/main/java/com/example/app/
    common/    GlobalExceptionHandler (problem JSON), RequestIdFilter (request id + access log), NotFoundException, PingController
    message/   SAMPLE FEATURE: entity, repository, service, controller, DTO records
  src/main/resources/db/migration/   Flyway SQL (V1__init.sql, ...)
  src/test/java/...                  MockMvc API tests (in-memory H2)
frontend/  React app on :5173, proxies /api -> :8080
  src/api/client.ts        the only place that calls fetch; throws ApiError {status, message, fieldErrors}
  src/components/          Layout (nav), Toast (useToast for notifications)
  src/pages/               one file per screen + *.test.tsx next to it
  src/types.ts             mirrors backend DTOs
  src/styles.css           design tokens + reusable classes (card, list, badge, toast...)
  e2e/                     Playwright tests on an isolated stack (:8081 in-memory DB + :5174), never the dev DB
docs/API.md                API contract (source of truth when backend and frontend are built in parallel)
docs/PLAN.template.md      template for a feature plan
logs/                      backend.log, frontend.log (written by dev.ps1)
```

## Commands (run from repo root)
Use the Git Bash wrappers (`./dev.sh`, `./verify.sh`, `./diagnose.sh`); they call the .ps1 scripts.

| Purpose | Command |
|---|---|
| Start app | `./dev.sh` (add `-Restart` or `-Stop`) |
| Verify everything | `./verify.sh` (`-SkipE2E` for fast loop) |
| Diagnose failures | `./diagnose.sh` |
| Backend tests only | `cd backend && mvn -q test` (one class: `mvn -q test -Dtest=MessageApiTest`) |
| Frontend unit tests | `cd frontend && npm test` |
| Frontend typecheck | `cd frontend && npm run typecheck` |
| E2E only (starts and stops its own stack) | `cd frontend && npx playwright test` |

PowerShell/cmd users can type `.\dev`, `.\verify`, `.\diagnose` instead (the .cmd wrappers).

## Definition of done (every task)
1. `./verify.sh` is green. Never report "done" without running it and pasting the summary table. With subagents, the lead runs it (see Speed rules); an agent working alone runs it itself.
2. New backend rule => unit test. New endpoint => integration test for success + each error status. New screen => UI test, and an e2e test for the main journey.
   - **Error coverage is never optional.** Every status code documented for an endpoint in `docs/API.md` (400, 401, 403, 404, 409, 422, ...) has its own automated test. Checking it by hand with curl does not count. If asked to keep tests minimal, cut extra cases, never these.
   - Report it as a table: `endpoint | status | test name`. Any status without a test name means the task is not done.
3. `docs/API.md` updated if the API changed.
4. On any failure: follow the `fullstack-doctor` skill. Do not guess-and-retry.

## Speed rules (inner loop vs gate)
- **Inner loop (agents):** while iterating, run only the tests you touched: `cd backend && mvn -q test -Dtest=<Class>` or `cd frontend && npx vitest run <file>`. Run your full slice (`mvn -q test` / `npm run typecheck && npm test`) once before reporting.
- **Gate (lead only):** `./verify.sh` once, after all agents report; `./verify.sh -SkipE2E` for quick checks in between. Subagents never run verify: parallel runs fight over ports and CPU.
- **Failures:** from the first unexpected failure, use the `fullstack-doctor` loop: evidence and a one-sentence hypothesis before every fix. Max 3 fix attempts (the doctor's cap), then stop and report Symptom/Layer/Evidence/Cause to the lead. No blind retries.
- **Test budget (default):** one unit test per business rule, one integration test per documented status code (required, see above), one concurrency test per shared-state write, one e2e test per main journey. No extras unless the lead asks.

## Backend conventions
- Layering: controller (HTTP only) -> service (business rules, `@Transactional`) -> repository. Entities never leave the service; return DTO records.
- Validate requests with Bean Validation on DTO records + `@Valid`. Errors go through `GlobalExceptionHandler` as problem JSON: `{status, detail, errors?, requestId}`.
- Status codes: 200 read, 201 create, 204 no body, 400 validation, 401/403 auth, 404 missing, 409 conflict with current state, 422 business rule violation.
- Schema changes: a NEW Flyway file `V{n}__desc.sql`. Never edit an applied migration.
- Log one INFO line per state change (what, id, outcome). Never log secrets.

## Frontend conventions
- All HTTP through `api` in `src/api/client.ts`. Types in `src/types.ts` match `docs/API.md`.
- Every data screen handles loading, error (with retry) and empty states. Forms: disable submit while submitting, show field errors, toast on success/failure.
- Inputs have visible `<label>`s (tests select by label/role, not CSS).
- Style with the classes and tokens in `styles.css`; add new ones there. No UI library.

## Parallel work rules (multiple agents)
- Agree the contract first in `docs/API.md`; then backend, frontend and test agents work at the same time.
- Ownership: backend-dev edits `backend/` only; frontend-dev edits `frontend/src/` only; test-engineer edits test files and `frontend/e2e/` only. Contract changes go back to the lead (human) first.
- Frontend can build against the contract before the backend exists (mock with `src/test/mockFetch.ts` in tests).
