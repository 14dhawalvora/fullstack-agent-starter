---
name: fullstack-verify
description: Prove the whole app works before saying "done" - backend tests, frontend typecheck and unit tests, live smoke checks through the Vite proxy, and Playwright end-to-end tests - and report a pass/fail table. Use after any change and before handing work back.
---

# Verify: "done" means green, with proof

## Steps
1. Subagents: don't run verify. Run only your own tests (see "Speed rules" in CLAUDE.md); the lead runs the gate.
2. Lead (or a single agent working alone): quick check with `./verify.sh -SkipE2E`; before reporting done, the full `./verify.sh` once (starts the app if needed, runs e2e).
3. Paste the summary table in your reply.
4. Any FAIL: switch to the `fullstack-doctor` skill. Do not rerun hoping it passes.

## What each step proves
| Step | Proves |
|---|---|
| Backend tests (`mvn clean test`) | unit rules + API contract, validation, error statuses, DB effects (in-memory H2) |
| Frontend typecheck | UI code matches `types.ts` (catches API shape drift) |
| Frontend unit tests (vitest) | screens render data/empty/error states and send the right requests |
| Smoke | backend healthy, frontend served, Vite proxy forwards `/api` (`/api/ping` = 200) |
| E2E (Playwright) | a real browser completes the main journeys on an isolated stack (backend :8081, in-memory DB seeded by Flyway, frontend :5174); the dev DB is never touched |

## Manual check for a new feature (30 seconds)
Open http://localhost:5173, do the new journey once, try one bad input, check the toast/error text.

## Rules
- Never skip, delete or loosen a test to get green. If a test is wrong, say why and fix it explicitly.
- A feature without tests is not done (see `unit-testing`, `integration-testing`, `react-ui-testing`).
