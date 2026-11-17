---
name: fullstack-doctor
description: Diagnose and fix a failing full-stack app (Spring Boot + React/Vite + H2) layer by layer - machine, database, backend, frontend, integration - using health checks and logs, then prove the fix with verify. Use when verify fails, the app won't start, the UI shows an error or blank page, or an API returns an unexpected status.
---

# Full-stack doctor: evidence first, one layer at a time

Goal: turn "it's broken" into **symptom -> failing layer -> evidence -> fix -> verified**, without guessing.

## Loop (max 3 fix attempts, then stop and report)
1. **Collect facts**: a single failing test with a clear assertion or stack trace -> skip `./diagnose.sh`, read the failure and start at the Tests layer. Otherwise run `./diagnose.sh` and read it top to bottom. Do not edit code yet.
2. **Locate the layer**: the first abnormal line wins. Use the table below. Lower layers first: a DB failure causes backend failures, which cause UI failures.
3. **State one hypothesis** in one sentence, with the evidence line that supports it.
4. **Smallest check** to confirm it (one curl, one test class, one log grep). If it is not confirmed, go back to step 2.
5. **Fix the root cause** (smallest change). Never weaken a test, delete data or disable a check to get green.
6. **Prove it**: rerun the narrowest failing check, then your own slice. The lead (or an agent working alone) runs `./verify.sh` and pastes the summary.
7. Still failing after 3 attempts: stop and report what you know (format below) to the lead; the human, if you are the lead.

## Layer map
| Layer | Healthy looks like | Typical failure evidence | Usual fix |
|---|---|---|---|
| Machine | ports 8080/5173 (dev) and 8081/5174 (e2e stack) free before start; Java 21, Node 18+ | "Port 8080 was already in use", EADDRINUSE, old pid alive | `dev.ps1 -Stop`; else `taskkill /PID <pid> /F` for the stale java/node |
| Database | health `db: UP`; Flyway "Successfully applied" / "up to date" | FlywayException, "checksum mismatch", "Table ... not found", "Database may be already in use" | Add a new migration instead of editing an old one; fix entity/column name mismatch; stale lock -> stop the other java process. Deleting `backend/data/` resets dev data: ask the human first |
| Backend | `/actuator/health` 200; `:8080/api/ping` 200 | APPLICATION FAILED TO START, BeanCreationException, COMPILATION ERROR, 500 + `requestId` | Read the first `Caused by:`; for 500s grep the requestId in `logs/backend.log` to find the stack trace |
| Frontend | `:5173/` 200; no errors in `logs/frontend.log` | TS error, "Failed to resolve import", blank page | `npm run typecheck`; fix the import/type; missing package -> `npm install` |
| Integration | `:5173/api/ping` 200 (proxy reaches Spring) | proxy 500/502/504 or ECONNREFUSED in frontend log | backend down (fix backend first) or wrong proxy target in `vite.config.ts` |
| Contract | UI shows the data | `undefined`, NaN, empty list while the API has data | compare `curl` output with `src/types.ts` and `docs/API.md`; fix the side that drifted |
| Tests | all green | assertion diff in surefire report or Playwright error-context | product bug or outdated test? Fix the product unless the requirement changed |

## Handy checks
```bash
curl -s http://localhost:8080/actuator/health
curl -s -i http://localhost:5173/api/ping                         # through the proxy
curl -s -i -H "Content-Type: application/json" -d '{"content":"hi"}' http://localhost:8080/api/messages
grep -n "<requestId>" logs/backend.log                             # stack trace for a 500
cd backend && mvn -q test -Dtest=MessageApiTest                    # one test class
cd frontend && npx playwright test -g "post a message"             # one e2e test
grep -E "ERROR|Caused by" logs/e2e-backend.log | tail            # e2e backend log (its own stack on :8081)
```

## Report format (always end with this)
```
Symptom:   <what failed, exact message>
Layer:     <machine | database | backend | frontend | integration | contract | tests>
Evidence:  <log line / status code / test name>
Cause:     <one sentence>
Fix:       <files changed, one line each>
Verified:  <narrowest check + your slice result; verify summary table only if you ran it>
```
