import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

// `vite --mode e2e` is used only by playwright.config.ts (isolated e2e stack on :8081).
export default defineConfig(({ mode }) => ({
  plugins: [react()],
  server: {
    port: 5173,
    strictPort: true,
    // Browser only talks to :5173; Vite forwards /api to Spring. Same origin => no CORS.
    proxy: { '/api': mode === 'e2e' ? 'http://localhost:8081' : 'http://localhost:8080' },
  },
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: './src/test/setup.ts',
    include: ['src/**/*.test.{ts,tsx}'],
  },
}));
