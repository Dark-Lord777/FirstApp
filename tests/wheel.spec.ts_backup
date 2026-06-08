import { test } from '@playwright/test';

test('Flutter startup debug', async ({ page }) => {
  page.on('console', msg => {
    console.log(`[${msg.type()}] ${msg.text()}`);
  });

  page.on('pageerror', err => {
    console.log(`[PAGEERROR] ${err.message}`);
  });

  page.on('requestfailed', req => {
    console.log(`[FAILED] ${req.url()}`);
  });

  await page.goto('/', { waitUntil: 'networkidle' });

  console.log('TITLE:', await page.title());

  console.log(
    'BODY:',
    await page.locator('body').innerHTML()
  );

  await page.screenshot({
    path: 'startup.png',
    fullPage: true,
  });

  await page.waitForTimeout(10000);
});
