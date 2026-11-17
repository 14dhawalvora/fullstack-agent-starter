# Plan: <feature>

## Users and journey
- Who: <user types>
- Journey (3-5 steps): 1. ... 2. ... 3. ...

## Scope
- Phase 1 (must work end to end, with its correctness rules): ...
- Phase 2 (enhancements, if time): ...
- Out of scope (say it out loud): ...
- Assumptions: ...

## Rules / invariants (what must always be true)
- ...

## Data model (new Flyway migration)
- table: columns, keys, constraints, indexes

## API (add rows to docs/API.md)
- METHOD /path -> success / errors

## Work split (parallel)
| Agent | Task | Done when |
|---|---|---|
| backend-dev | migration + endpoints + unit/integration tests | `mvn test` green |
| frontend-dev | screens against the contract + UI tests | `npm test` green |
| test-engineer | e2e journeys + edge-case API tests | written; run verify when features land |

## Risks and follow-ups
- ...
