import { test, expect } from '@playwright/test';

test('Flutter приложение загрузилось и кнопка нажимается', async ({ page }) => {
  // Идем на страницу
  await page.goto('/', { waitUntil: 'networkidle' });
  
  // Ждем появления кнопки (ждет до 30 секунд)
  await page.waitForSelector('button', { timeout: 30000 });
  
  // Находим кнопку Spin
  const spinButton = page.getByText('Spin');
  await spinButton.waitFor({ state: 'visible' });
  
  // КЛИКАЕМ!
  await spinButton.click();
  
  // Проверяем, что что-то изменилось (появилось значение, изменился текст и т.д.)
  // Здесь добавь свою проверку
  await expect(page.locator('body')).not.toContainText('error');
});
