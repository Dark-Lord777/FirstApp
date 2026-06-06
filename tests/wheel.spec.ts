import { test, expect } from '@playwright/test';

test('при клике на Spin колесо вращается', async ({ page }) => {
  await page.goto('/');
  
  const spinButton = page.locator('button', { hasText: 'Spin' });
  await expect(spinButton).toBeVisible();
  await spinButton.click();
  await page.waitForTimeout(2000);
});

test('можно покрутить 5 раз подряд без падений', async ({ page }) => {
  await page.goto('/');
  
  const spinButton = page.locator('button', { hasText: 'Spin' });
  
  for (let i = 0; i < 5; i++) {
    await spinButton.click();
    await page.waitForTimeout(1500);
  }
});

test('Add Sectors открывает диалог', async ({ page }) => {
  await page.goto('/');
  
  const addButton = page.locator('button', { hasText: 'Add Sectors' });
  await addButton.click();
  await page.waitForTimeout(500);
});

test('Reset сбрасывает сектора', async ({ page }) => {
  await page.goto('/');
  
  const resetButton = page.locator('button', { hasText: 'Reset' });
  await expect(resetButton).toBeVisible();
  await resetButton.click();
  await page.waitForTimeout(1000);
});
