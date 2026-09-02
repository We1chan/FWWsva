/* 阶段4 E2E：布控新增页行为类型含 sleep_duty（睡岗）取证 */
const { chromium } = require('playwright-core');
const path = require('path');
const fs = require('fs');

const CHROME = 'C:/Users/19904/.agent-browser/browsers/chrome-152.0.7977.75/chrome.exe';
const OUT = 'C:/Users/19904/Documents/ChatGPT/sva/FWWsva/docs/evidence-phase4';
const ts = () => { const d = new Date(); const p = n => String(n).padStart(2, '0'); return `${d.getFullYear()}${p(d.getMonth()+1)}${p(d.getDate())}-${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`; };
const TS = ts();
const shots = [];
const log = m => console.log('[p4d] ' + m);
const sleep = ms => new Promise(r => setTimeout(r, ms));

(async () => {
  const browser = await chromium.launch({ executablePath: CHROME, headless: true, args: ['--no-sandbox', '--disable-gpu'] });
  const page = await browser.newPage({ viewport: { width: 1700, height: 950 } });
  page.setDefaultTimeout(15000);

  const shot = async (name, note) => {
    await sleep(500);
    const f = `${name}-${TS}.png`;
    await page.screenshot({ path: path.join(OUT, f) });
    shots.push({ name, file: f, note, url: page.url() });
    log(`shot ${f}`);
  };
  const clickMenu = async (level1, level2) => {
    const sub = page.locator(`.el-menu-item:visible:has-text("${level2}")`);
    if (await sub.count()) { await sub.first().click(); }
    else {
      await page.click(`.el-submenu__title:has-text("${level1}")`);
      await sleep(700);
      await page.locator(`.el-menu-item:has-text("${level2}")`).first().click({ force: true });
    }
    await sleep(1800);
  };

  try {
    await page.goto('http://localhost/#/login', { timeout: 30000 });
    await page.waitForSelector('input[placeholder="账号"]');
    await page.fill('input[placeholder="账号"]', 'admin');
    await page.fill('input[placeholder="密码"]', 'admin123');
    await page.click('button:has-text("登 录")');
    await sleep(3500);
    await page.goto('http://localhost/#/index', { timeout: 30000 });
    await page.waitForSelector('.el-submenu__title', { timeout: 15000 });
    await sleep(1000);

    // 布控管理 -> 布控管理（add.vue：布控新增）
    await clickMenu('布控管理', '布控列表');
    await sleep(800);
    // 布控列表页找"新增布控"按钮进入 add 表单（路径不确定，优先直接路由）
    await page.goto('http://localhost/#/deployment/add', { timeout: 30000 });
    await sleep(2500);

    // 先点击"添加算法"，使行为规则区域出现
    const addAlg = page.locator('button:has-text("添加算法")');
    if (await addAlg.count()) { await addAlg.first().click(); await sleep(2000); }
    // 展开第一个"请选择行为"下拉
    let behaviorDropdownOk = false;
    const selCount = await page.evaluate(() => document.body.innerText.includes('请选择行为'));
    log('page has 请选择行为 text=' + selCount);
    if (selCount) {
      const behaviorSel = page.locator('input[placeholder="请选择行为"]').first();
      if (await behaviorSel.count()) {
        await behaviorSel.click();
        await sleep(1200);
        const opts = await page.evaluate(() => [...document.querySelectorAll('.el-select-dropdown:not([style*="display: none"]) .el-select-dropdown__item, .el-select-dropdown__item:visible')].map(o => o.textContent.trim()).filter(Boolean).slice(0, 30));
        log('behavior opts=' + JSON.stringify(opts));
        const hasSleepDuty = opts.some(o => /睡岗/.test(o) || o === 'sleep_duty');
        behaviorDropdownOk = hasSleepDuty;
        if (hasSleepDuty) {
          await shot('p4-06-deployment-sleep-duty', `布控新增 行为下拉含 睡岗（sleep_duty）opts=${opts.length}`);
        }
        await page.keyboard.press('Escape');
      } else log('WARN 未找到 请选择行为 输入框');
    }
    log('RESULT sleep_duty_in_dropdown=' + behaviorDropdownOk);
    fs.writeFileSync(path.join(OUT, `p4d-summary-${TS}.json`), JSON.stringify({ ts: TS, shots, sleepDutyInDropdown: behaviorDropdownOk }, null, 2), 'utf8');
    log('ALL DONE');
  } catch (e) {
    log('ERROR: ' + e.message);
  } finally {
    await browser.close();
  }
})();
