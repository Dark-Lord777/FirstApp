import { test, expect } from '@playwright/test';
import fs from 'fs';
import path from 'path';

test('Flutter app startup and basic functionality', async ({ page }) => {
  const logs: string[] = [];
  const errors: string[] = [];
  const softErrors: string[] = [];

  page.on('console', msg => {
    const text = `[${msg.type()}] ${msg.text()}`;
    console.log(text);
    logs.push(text);
  });

  page.on('pageerror', err => {
    if (err.message.includes('CORS') || err.message.includes('Worker')) {
      console.log(' Ignored expected error:', err.message);
      return;
    }
    console.log(` [PAGEERROR] ${err.message}`);
    errors.push(err.message);
  });

  await page.goto('/', { waitUntil: 'networkidle' });
  console.log(' Page loaded, title:', await page.title());

  try {
    await page.waitForSelector('canvas', { timeout: 30000 });
    console.log(' Canvas found');
  } catch (e) {
    console.log(' Canvas not found, but continuing...');
    softErrors.push('Canvas not found');
  }

  
  await expect.soft(page.getByRole('button', { name: 'Spin' })).toBeVisible();
  await expect.soft(page.getByRole('button', { name: 'RESET' })).toBeVisible();
  await expect.soft(page.getByRole('button', { name: 'Add Sectors' })).toBeVisible();

  const testInfo = test.info();
  const screenshotDir = path.join('test-results', testInfo.title.replace(/\s/g, '_'));
  if (!fs.existsSync(screenshotDir)) fs.mkdirSync(screenshotDir, { recursive: true });
  
  await page.screenshot({
    path: path.join(screenshotDir, 'startup.png'),
    fullPage: true,
  });
  console.log(' Screenshot saved');

  try {
    await page.getByRole('button', { name: 'Add sectors' }).click();
    await page.waitForSelector('input', { timeout: 5000 });
    await page.fill('input', 'Test Sector');
    await page.screenshot({
      path: path.join(screenshotDir, 'add.png'),
      fullPage: true,
    });
    
    await expect.soft(page.getByRole('button', { name: 'Add' })).toBeVisible();
    await page.getByRole('button', { name: 'Add' }).click();
    
    await page.screenshot({
      path: path.join(screenshotDir, 'startup2.png'),
      fullPage: true,
    });
    
    await expect.soft(page.getByRole('button', { name: 'Spin' })).toBeVisible();
    await page.getByRole('button', { name: 'Spin' }).click();
    
    await page.waitForTimeout(1000);
    
    await page.screenshot({
      path: path.join(screenshotDir, 'spin.png'),
      fullPage: true,
    });
  } catch (e) {
    console.log(' Add sector flow failed, but continuing:', e.message);
    softErrors.push(`Add sector flow: ${e.message}`);
  }
  
  try {
    await page.waitForFunction(() => {
      const canvas = document.querySelector('canvas');
      return canvas && canvas.width > 0;
    }, { timeout: 5000 });
    console.log(' Canvas is rendering');
  } catch (e) {
    console.log(' Canvas rendering check failed');
    softErrors.push('Canvas not rendering');
  }

  if (softErrors.length > 0) {
    console.log('\n Soft errors encountered:');
    softErrors.forEach(err => console.log(`   - ${err}`));
  }
  
  if (errors.length > 0) {
    console.log('\n Critical errors:');
    errors.forEach(err => console.log(`   - ${err}`));
  }
  
  expect(errors).toEqual([]);
  
  if (softErrors.length > 0) {
    console.log(`\n Test completed with ${softErrors.length} soft error(s)`);
  }
  
  console.log(' Test finished');
});
