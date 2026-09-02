const { chromium } = require('playwright-core');
const CHROME = 'C:/Users/19904/.agent-browser/browsers/chrome-152.0.7977.75/chrome.exe';
(async () => {
  const browser = await chromium.launch({ executablePath: CHROME, headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage({ viewport: { width: 1600, height: 900 } });
  await page.goto('http://localhost/#/login', { timeout: 30000 });
  await page.waitForTimeout(3000);
  const info = await page.evaluate(() => {
    const ins = [...document.querySelectorAll('input')].map(i => ({ ph: i.placeholder, type: i.type, cls: i.className.slice(0, 60) }));
    const btns = [...document.querySelectorAll('button')].map(b => (b.textContent || '').trim().slice(0, 20));
    const bodyText = document.body.innerText.slice(0, 400);
    return { ins, btns, bodyText };
  });
  console.log(JSON.stringify(info, null, 1));
  await browser.close();
})();
