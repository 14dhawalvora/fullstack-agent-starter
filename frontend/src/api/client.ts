// The only place that calls fetch. Pages use `api.*` and catch ApiError.

export class ApiError extends Error {
  readonly status: number;
  readonly fieldErrors: Record<string, string>;
  readonly requestId?: string;

  constructor(status: number, message: string, fieldErrors: Record<string, string> = {}, requestId?: string) {
    super(message);
    this.status = status;
    this.fieldErrors = fieldErrors;
    this.requestId = requestId;
  }
}

async function request<T>(method: string, path: string, body?: unknown, headers: Record<string, string> = {}): Promise<T> {
  const init: RequestInit = { method, credentials: 'same-origin', headers: { ...headers } };
  if (body !== undefined) {
    init.headers = { ...headers, 'Content-Type': 'application/json' };
    init.body = JSON.stringify(body);
  }

  let res: Response;
  try {
    res = await fetch(`/api${path}`, init);
  } catch {
    throw new ApiError(0, 'Cannot reach the server. Is the backend running?');
  }

  if (res.status === 204) return undefined as T;
  const data = await res.json().catch(() => null);
  if (!res.ok) {
    // Backend errors are RFC 7807 problem JSON: { detail, errors?, requestId }
    throw new ApiError(res.status, data?.detail ?? `Request failed (${res.status})`, data?.errors ?? {}, data?.requestId);
  }
  return data as T;
}

export const api = {
  get: <T>(path: string) => request<T>('GET', path),
  post: <T>(path: string, body?: unknown, headers?: Record<string, string>) => request<T>('POST', path, body, headers),
  put: <T>(path: string, body?: unknown) => request<T>('PUT', path, body),
  del: <T>(path: string) => request<T>('DELETE', path),
};
