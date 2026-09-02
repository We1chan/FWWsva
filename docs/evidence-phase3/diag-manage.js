const { chromium } = require('playwright-core');
const CHROME = 'C:/Users/19904/.agent-browser/browsers/chrome-152.0.7977.75/chrome.exe';
const sleep = ms => new Promise(r => setTimeout(r, ms));
(async () => {
  const browser = await chromium.launch({ executablePath: CHROME, headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage({ viewport: { width: 1600, height: 950 } });
  page.setDefaultTimeout(12000);
  try {
    await page.goto('http://localhost/#/login', { timeout: 30000 });
    await page.waitForSelector('input[placeholder="账号"]');
    await page.fill('input[placeholder="账号"]', 'admin');
    await page.fill('input[placeholder="密码"]', 'admin123');
    await page.click('button:has-text("登 录")');
    await sleep(3000);
    await page.goto('http://localhost/#/index', { timeout: 30000 });
    await page.waitForSelector('.el-submenu__title');
    await sleep(800);
    await page.click('.el-submenu__title:has-text("设备管理")');
    await sleep(600);
    await page.click('.el-menu-item:has-text("设备管理")');
    await sleep(1500);
    // 抓查询表单区结构
    const info = await page.evaluate(() => {
      const form = document.querySelector('.app-container .el-form') || document.querySelector('form');
      const selects = [...document.querySelectorAll('.el-form .el-select')].filter(s => s.offsetParent !== null).map(s => {
        const lbl = s.closest('.el-form-item')?.querySelector('.el-form-item__label')?.textContent || '';
        const ph = s.querySelector('input')?.placeholder || '';
        return { label: lbl, placeholder: ph, cls: s.className.slice(0, 50) };
      });
      const btns = [...document.querySelectorAll('.el-form button')].filter(b => b.offsetParent !== null).map(b => (b.textContent || '').trim());
      const toolbar = [...document.querySelectorAll('.app-container button, .toolbar button')].filter(b => b.offsetParent !== null).map(b => (b.textContent || '').trim()).slice(0, 15);
      return { selects, btns, toolbar };
    });
    console.log(JSON.stringify(info, null, 1));
  } finally { await browser.close(); }
})();
