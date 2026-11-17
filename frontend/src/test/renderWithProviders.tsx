import { render } from '@testing-library/react';
import type { ReactElement } from 'react';
import { MemoryRouter } from 'react-router-dom';
import { ToastProvider } from '../components/Toast';
import { routerFuture } from '../routerFuture';

/** Render a page with the same providers the app uses (router + toasts). */
export function renderWithProviders(ui: ReactElement, { route = '/' } = {}) {
  return render(
    <MemoryRouter initialEntries={[route]} future={routerFuture}>
      <ToastProvider>{ui}</ToastProvider>
    </MemoryRouter>,
  );
}
