import { defineConfig, devices } from '@playwright/test';

// E2E runs on its OWN stack, separate from the dev app (dev.sh: :8080 + :5173, file DB):
//   backend  :8081  Spring profile "e2e" -> in-memory H2, fresh Flyway seed every run
//   frontend :5174  Vite, proxying /api to :8081
// Playwright starts both, runs the tests, then stops them. Dev data is never touched,
// so tests can assert exact values from the seed data.
const BACKEND = 'http://localhost:8081';
const FRONTEND = 'http://localhost:5174';

export default defineConfig({
  testDir: './e2e',
  timeout: 30_000,
  retries: 0,
  reporter: [['list']],
  use: {
    baseURL: FRONTEND,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
  webServer: [
    {
      command: 'mvn -q spring-boot:run -Dspring-boot.run.profiles=e2e',
      cwd: '../backend',
      url: `${BACKEND}/actuator/health`,
      timeout: 180_000,
      reuseExistingServer: false, // always a fresh in-memory DB
    },
    {
      command: 'npx vite --mode e2e --port 5174 --strictPort',
      url: FRONTEND,
      timeout: 60_000,
      reuseExistingServer: false,
    },
  ],
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
});
