import { test, expect } from '@playwright/test';

test('страница открывается', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveTitle(/.*/);
  await page.waitForTimeout(2000);
});

test('кнопки существуют', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('button', { hasText: 'Spin' })).toBeVisible();
  await expect(page.locator('button', { hasText: 'Add Sectors' })).toBeVisible();
  await expect(page.locator('button', { hasText: 'RESET' })).toBeVisible();
});
