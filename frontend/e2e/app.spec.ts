import { expect, test } from '@playwright/test';

test('post a message and see it after reload', async ({ page }) => {
  await page.goto('/', { waitUntil: 'networkidle' }); // page fully loaded, initial data fetched
  await expect(page.getByRole('heading', { name: 'Messages' })).toBeVisible();

  const text = `e2e message ${Date.now()}`;
  await page.getByLabel('New message').fill(text);
  await page.getByRole('button', { name: 'Post message' }).click();
  // Assert on the list item, not getByText: the typed text in the textarea would match too early.
  const posted = page.getByRole('listitem').filter({ hasText: text });
  await expect(posted).toBeVisible();
  await expect(page.getByRole('status').filter({ hasText: 'Message posted' })).toBeVisible();

  await page.reload(); // persisted in the database
  await expect(page.getByRole('listitem').filter({ hasText: text })).toBeVisible();
});
