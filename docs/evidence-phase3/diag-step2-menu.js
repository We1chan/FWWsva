/* phase3 step2：登录后进入后台布局，dump 菜单并保存登录态 cookie */
const { chromium } = require('playwright-core');
const path = require('path');
const fs = require('fs');

const CHROME = 'C:/Users/19904/.agent-browser/browsers/chrome-152.0.7977.75/chrome.exe';
const OUT = 'C:/Users/19904/Documents/ChatGPT/sva/FWWsva/docs/evidence-phase3';

(async () => {
  const browser = await chromium.launch({ executablePath: CHROME, headless: true, args: ['--no-sandbox'] });
  const context = await browser.newContext({ viewport: { width: 1600, height: 900 } });
  const page = await context.newPage();
  const log = m => console.log('[step2] ' + m);

  try {
    await page.goto('http://localhost/#/login', { timeout: 30000 });
    await page.waitForSelector('input[placeholder="账号"]', { timeout: 15000 });
    await page.fill('input[placeholder="账号"]', 'admin');
    await page.fill('input[placeholder="密码"]', 'admin123');
    await page.click('button:has-text("登 录")');
    await page.waitForTimeout(3500);
    log('after login url=' + page.url());

    // 保存登录态 cookie 供后续复用
    const cookies = await context.cookies();
    fs.writeFileSync(path.join(OUT, 'p3-cookies.json'), JSON.stringify(cookies, null, 2), 'utf8');
    log('cookies saved: ' + cookies.map(c => c.name).join(','));
    const lsKeys = await page.evaluate(() => Object.keys(localStorage));
    log('localStorage keys=' + JSON.stringify(lsKeys));

    // 进入后台首页
    await page.goto('http://localhost/#/index', { timeout: 30000 });
    await page.waitForTimeout(3000);
    log('index url=' + page.url());

    const menus = await page.evaluate(() => {
      const out = [];
      document.querySelectorAll('.el-submenu__title, .el-menu-item, .el-submenu .el-menu--inline .el-menu-item').forEach(el => {
        const t = (el.textContent || '').trim().replace(/\s+/g, ' ');
        const visible = el.offsetParent !== null;
        if (t && t.length < 40 && visible) out.push({ t, visible });
      });
      // 收集所有 el-menu-item 的文本（含隐藏子菜单）
      const all = [];
      document.querySelectorAll('.el-menu-item').forEach(el => {
        const t = (el.textContent || '').trim().replace(/\s+/g, ' ');
        if (t && t.length < 40) all.push(t);
      });
      return { visible: out.slice(0, 60), all: all.slice(0, 80) };
    });
    log('VISIBLE=' + JSON.stringify(menus.visible));
    log('ALL-ITEMS=' + JSON.stringify(menus.all));

    await page.screenshot({ path: path.join(OUT, 'p3-03-admin-index.png') });
    log('index shot saved');
  } catch (e) {
    log('ERROR: ' + e.message);
  } finally {
    await browser.close();
  }
})();
