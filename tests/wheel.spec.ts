import { test, expect } from '@playwright/test';

test('Spin button works', async ({ page }) => {
  await page.goto('/', { waitUntil: 'networkidle' });
  
  // Ждем появления canvas (признак что Flutter запустился)
  await page.waitForSelector('canvas', { timeout: 45000 });
  
  // Теперь ждем кнопку (она появится через несколько секунд после canvas)
  await page.waitForSelector('button', { timeout: 15000 });
  
  // Кликаем
  await page.getByText('Spin').click();
  
  // Проверяем, что нет ошибок
  await expect(page.locator('body')).not.toContainText('error');
});
