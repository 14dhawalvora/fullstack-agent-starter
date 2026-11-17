import { useCallback, useEffect, useState, type FormEvent } from 'react';
import { api, ApiError } from '../api/client';
import { useToast } from '../components/Toast';
import type { Message } from '../types';

// Sample page. Patterns to copy: load on mount, loading/error/empty states,
// a form with field errors, submit disabled while submitting, toast on success/failure.
export function MessagesPage() {
  const toast = useToast();
  const [messages, setMessages] = useState<Message[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);

  const [content, setContent] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [fieldError, setFieldError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setLoadError(null);
    try {
      setMessages(await api.get<Message[]>('/messages/latest?limit=20'));
    } catch (err) {
      setLoadError(err instanceof ApiError ? err.message : 'Could not load messages');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setFieldError(null);
    try {
      const created = await api.post<Message>('/messages', { content });
      setMessages((prev) => [created, ...prev]);
      setContent('');
      toast('success', 'Message posted');
    } catch (err) {
      const message = err instanceof ApiError ? err.message : 'Could not post message';
      setFieldError(err instanceof ApiError ? (err.fieldErrors.content ?? null) : null);
      toast('error', message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <section className="stack">
      <div className="page-header">
        <h1>Messages</h1>
        <p className="muted">Latest messages from the backend.</p>
      </div>

      <form className="card stack-sm" onSubmit={handleSubmit}>
        <label>
          New message
          <textarea value={content} onChange={(e) => setContent(e.target.value)} maxLength={500} rows={2} />
        </label>
        {fieldError && <span className="field-error">{fieldError}</span>}
        <div className="row-end">
          <button type="submit" disabled={submitting || content.trim() === ''}>
            {submitting ? 'Posting…' : 'Post message'}
          </button>
        </div>
      </form>

      {loadError && (
        <div className="card error-card" role="alert">
          {loadError}{' '}
          <button className="link" onClick={load}>
            Retry
          </button>
        </div>
      )}

      {loading && <div className="card muted">Loading…</div>}

      {!loading && !loadError && messages.length === 0 && (
        <div className="card empty">No messages yet. Post the first one above.</div>
      )}

      {messages.length > 0 && (
        <ul className="list card">
          {messages.map((m) => (
            <li key={m.id} className="list-item">
              <p>{m.content}</p>
              <time className="muted small" dateTime={m.createdAt}>
                {new Date(m.createdAt).toLocaleString()}
              </time>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
