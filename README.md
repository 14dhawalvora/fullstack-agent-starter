# Full-stack starter

Spring Boot 3 (Java 21) + H2 (Postgres mode, Flyway) + React 18 (TypeScript, Vite). Runs natively on Windows, no Docker.
Sample feature: a message board (post a message, list the latest).

## Run
Prereqs: JDK 21, Maven, Node 18+. From this folder in Git Bash:
```bash
./dev.sh               # starts backend :8080 + frontend :5173, logs in ./logs/
./verify.sh            # backend tests, typecheck, unit tests, smoke, e2e -> pass/fail table
./verify.sh -SkipE2E   # faster inner loop
./diagnose.sh          # read-only health + log report per layer
./dev.sh -Stop
```
(PowerShell/cmd: `.\dev`, `.\verify`, `.\diagnose`.)
First e2e run only: `cd frontend && npx playwright install chromium`. E2E starts its own backend (:8081, in-memory DB) and frontend (:5174), so it never changes your dev data.
Open http://localhost:5173.

## Architecture
```
Browser -> Vite dev server :5173 (React) --/api proxy--> Spring Boot :8080 -> H2 file DB (./backend/data)
```
- Same origin through the proxy: no CORS setup, cookies work if auth is added.
- Backend: controller -> service (@Transactional) -> repository; DTO records; one exception handler (problem JSON); request id + latency in every API log line; actuator health + metrics.
- Frontend: one API client, pages with loading/error/empty states, toast notifications, plain CSS design tokens.

## Why these choices
| Choice | Reason | Alternative |
|---|---|---|
| Spring Boot (Java) | validation, transactions, actuator built in; my strongest stack | Kotlin/Spring, Node |
| H2 file DB + Flyway | zero install, real SQL and transactions, versioned schema; swap URL for Postgres | Dockerized Postgres |
| REST | simple resources and commands, easy to curl and test | GraphQL (many clients needing different shapes) |
| React + TS + Vite | types catch API drift; fast dev server with proxy | Next.js (SSR not needed here) |
| JUnit/MockMvc, Vitest/RTL, Playwright | test pyramid: many fast tests, few full journeys | manual testing |

## Agent harness
- `CLAUDE.md`: map, commands, conventions, definition of done.
- `.claude/skills/`: `fullstack-verify`, `fullstack-doctor`, `unit-testing`, `integration-testing`, `react-ui-testing`, `observability`.
- `.claude/agents/`: `backend-dev`, `frontend-dev`, `test-engineer` for parallel work against `docs/API.md`.
- `.claude/settings.json`: pre-approved build/test commands so agents run without stopping.

## Testing multiple sessions
Windows in the same browser profile share cookies. To run two sessions at once, use one normal window and one private (Incognito) window.
