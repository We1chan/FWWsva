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
    await sleep(1800);
    const info = await page.evaluate(() => {
      const wrappers = document.querySelectorAll('.el-table__body-wrapper');
      const out = { wrappers: wrappers.length, fixed: !!document.querySelector('.el-table__fixed'), headers: [] };
      document.querySelectorAll('.el-table__header-wrapper th').forEach(h => out.headers.push((h.innerText || '').trim()));
      out.rows = [];
      const rows = [...document.querySelectorAll('.el-table__body-wrapper tbody tr')].filter(r => r.offsetParent !== null);
      rows.forEach((r, i) => {
        const btns = [...r.querySelectorAll('button')].map(b => {
          const rect = b.getBoundingClientRect();
          const st = getComputedStyle(b);
          return { text: (b.textContent || '').trim().slice(0, 10), w: Math.round(rect.width), vis: st.visibility, disp: st.display, opacity: st.opacity };
        });
        out.rows.push({ idx: i, cells: r.innerText.split('\n').slice(0, 6).join('|'), btns });
      });
      return out;
    });
    console.log(JSON.stringify(info, null, 1));
  } finally { await browser.close(); }
})();
