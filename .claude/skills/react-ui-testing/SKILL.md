---
name: react-ui-testing
description: Test React + TypeScript screens with Vitest and React Testing Library (mocked fetch) and cover main user journeys with Playwright on an isolated stack (own backend + in-memory DB). Use when adding or changing a page, form or UI flow.
---

# React UI testing

| Level | Tool | Where | Speed | Use for |
|---|---|---|---|---|
| Page/component | Vitest + React Testing Library + `mockFetch` | `src/pages/X.test.tsx` | ms | every UI state and the request a screen sends |
| Journey | Playwright | `e2e/*.spec.ts` | seconds | 1-3 critical flows through real backend + DB |

## Page test pattern (copy `src/pages/MessagesPage.test.tsx`)
```tsx
mockFetch({
  'GET /api/things?limit=20': { status: 200, body: [] },
  'POST /api/things': { status: 201, body: { id: 2, name: 'x' } },
});
renderWithProviders(<ThingsPage />);
await userEvent.type(await screen.findByLabelText('Name'), 'x');
await userEvent.click(screen.getByRole('button', { name: 'Add' }));
expect(await screen.findByText('x')).toBeInTheDocument();
```
- Route keys are `"METHOD /api/path?query"` exactly as the page calls them; unmocked routes return 404 with a clear message.
- `mockFetch` returns the spy: assert request bodies/headers with `spy.mock.calls`.
- Query by **role and label** (`getByRole('button', {name})`, `getByLabelText`), never CSS classes. If you can't, the UI lacks a label: fix the UI.
- Use `findBy*` for anything async. `renderWithProviders` adds the router and toasts.

## States every data screen should be tested for
1. Data shown after load
2. Empty state
3. Server error -> alert/toast text (+ retry if offered)
4. Form: field errors shown; submit disabled while submitting; success updates the screen
5. Server-side rejection (4xx with `detail`) shows the message to the user

## Playwright journey pattern (copy `e2e/app.spec.ts`)
```ts
await page.goto('/');
await page.getByLabel('Name').fill(`item ${Date.now()}`);   // unique data: the dev DB persists
await page.getByRole('button', { name: 'Add' }).click();
await expect(page.getByText(/item \d+/)).toBeVisible();
await page.reload();                                          // proves persistence
```
- Two users at once: `const ctxB = await browser.newContext();` gives a separate cookie jar (like an Incognito window).

## Run
`cd frontend && npm test` (units) · `npx playwright test -g "<name>"` (one journey; Playwright starts its own stack on :8081 + :5174, fresh seed data each run, so exact values are safe to assert) · failure traces in `frontend/test-results/`.
