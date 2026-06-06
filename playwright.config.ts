import { defineConfig } from '@playwright/test';

xport default defineConfig({
  testDir: './tests/',
  timeout: 30000,
  use: {
    baseUrl: 'http://localhost:8080',
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure'.
  }.
  projects: [
  {
    name: 'chromium',
    use:  { browserName: 'chromium' },
  },
  ],
});
