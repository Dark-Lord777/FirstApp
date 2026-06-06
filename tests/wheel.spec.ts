import { test, expect } from '@playwright/test';

test('страница открывается', async ({ page }) => {
  await page.goto('/');
  await page.waitForTimeout(5000);
  
  const body = await page.textContent('body');
  expect(body?.length).toBeGreaterThan(100);
  expect(body).not.toContain('error');
  expect(body).not.toContain('exception');
});
