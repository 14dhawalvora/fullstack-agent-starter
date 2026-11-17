import { vi } from 'vitest';

export interface MockRoute {
  status: number;
  body?: unknown;
}

/**
 * Replace global fetch with a route table keyed by "METHOD /api/path?query".
 * Unknown routes return 404 so a missing mock shows up clearly in the test failure.
 * Returns the spy so tests can assert on calls (e.g. request bodies).
 */
export function mockFetch(routes: Record<string, MockRoute>) {
  const spy = vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
    const key = `${init?.method ?? 'GET'} ${String(input)}`;
    const route = routes[key] ?? { status: 404, body: { detail: `No mock for ${key}` } };
    const payload = route.body === undefined || route.status === 204 ? null : JSON.stringify(route.body);
    return new Response(payload, { status: route.status, headers: { 'Content-Type': 'application/json' } });
  });
  vi.stubGlobal('fetch', spy);
  return spy;
}
