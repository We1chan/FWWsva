/* phase3 浏览器取证 step1：登录 + dump 菜单结构 */
const { chromium } = require('playwright-core');
const path = require('path');

const CHROME = 'C:/Users/19904/.agent-browser/browsers/chrome-152.0.7977.75/chrome.exe';
const OUT = 'C:/Users/19904/Documents/ChatGPT/sva/FWWsva/docs/evidence-phase3';
const TS = () => {
  const d = new Date();
  const p = n => String(n).padStart(2, '0');
  return `${d.getFullYear()}${p(d.getMonth() + 1)}${p(d.getDate())}-${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`;
};

(async () => {
  const ts = TS();
  const browser = await chromium.launch({ executablePath: CHROME, headless: true, args: ['--no-sandbox', '--disable-gpu'] });
  const page = await browser.newPage({ viewport: { width: 1600, height: 900 } });
  const log = m => console.log(`[step1] ${m}`);

  try {
    log('goto login');
    await page.goto('http://localhost/', { timeout: 30000, waitUntil: 'networkidle' });
    await page.waitForTimeout(1500);
    log('url=' + page.url());

    // 登录表单填写
    const userSel = 'input[placeholder="账号"]';
    const pwdSel = 'input[placeholder="密码"]';
    await page.waitForSelector(userSel, { timeout: 15000 });
    await page.fill(userSel, 'admin');
    await page.fill(pwdSel, 'admin123');
    await page.screenshot({ path: path.join(OUT, `p3-01-login-filled-${ts}.png`) });
    log('filled, click login');
    await page.click('button:has-text("登 录"), button:has-text("登录")');
    await page.waitForTimeout(4000);
    log('after login url=' + page.url());

    // token 状态
    const auth = await page.evaluate(() => {
      const ls = {};
      for (let i = 0; i < localStorage.length; i++) {
        const k = localStorage.key(i);
        if (/token|user|permission|name/i.test(k)) ls[k] = String(localStorage.getItem(k)).slice(0, 60);
      }
      return { ls, path: location.pathname, hash: location.hash };
    });
    log('auth keys=' + JSON.stringify(auth));

    await page.screenshot({ path: path.join(OUT, `p3-02-home-${ts}.png`) });
    log('home shot saved');

    // dump 侧边菜单
    const menus = await page.evaluate(() => {
      const out = [];
      document.querySelectorAll('.el-submenu__title, .el-menu-item').forEach(el => {
        const t = (el.textContent || '').trim().replace(/\s+/g, ' ');
        if (t && t.length < 30) out.push(t);
      });
      return out;
    });
    log('MENUS=' + JSON.stringify(menus, null, 0));

    // 全页静态文本快照（找设备管理相关菜单链接）
    const links = await page.evaluate(() => {
      const out = [];
      document.querySelectorAll('a[href], .el-menu-item, li').forEach(el => {
        const t = (el.textContent || '').trim().replace(/\s+/g, ' ').slice(0, 40);
        const h = el.getAttribute('href') || '';
        if (/设备|监控|预览|布控|告警/i.test(t + h) && t.length < 40 && !out.find(o => o.t === t)) out.push({ t, h });
      });
      return out.slice(0, 40);
    });
    log('DEV-LINKS=' + JSON.stringify(links, null, 0));
    require('fs').writeFileSync(path.join(OUT, `p3-menu-${ts}.json`), JSON.stringify({ auth, menus, links }, null, 2), 'utf8');
    log('menu json saved');
  } catch (e) {
    log('ERROR: ' + e.message);
  } finally {
    await browser.close();
  }
})();
