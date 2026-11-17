import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it } from 'vitest';
import { mockFetch } from '../test/mockFetch';
import { renderWithProviders } from '../test/renderWithProviders';
import { MessagesPage } from './MessagesPage';

describe('MessagesPage', () => {
  it('shows messages from the backend', async () => {
    mockFetch({
      'GET /api/messages/latest?limit=20': {
        status: 200,
        body: [{ id: 1, content: 'Hello', createdAt: '2026-01-01T00:00:00Z' }],
      },
    });
    renderWithProviders(<MessagesPage />);
    expect(await screen.findByText('Hello')).toBeInTheDocument();
  });

  it('posts a message and puts it at the top', async () => {
    mockFetch({
      'GET /api/messages/latest?limit=20': {
        status: 200,
        body: [{ id: 1, content: 'Old', createdAt: '2026-01-01T00:00:00Z' }],
      },
      'POST /api/messages': { status: 201, body: { id: 2, content: 'New', createdAt: '2026-01-02T00:00:00Z' } },
    });
    renderWithProviders(<MessagesPage />);

    await screen.findByText('Old');
    await userEvent.type(screen.getByLabelText('New message'), 'New');
    await userEvent.click(screen.getByRole('button', { name: 'Post message' }));

    const items = await screen.findAllByRole('listitem');
    expect(items[0]).toHaveTextContent('New');
  });
});
