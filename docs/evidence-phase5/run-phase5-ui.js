/* 阶段5 E2E UI 取证：RTSP/GB28181 睡岗告警（ws 链路回传）、原 YOLO 回归、布控列表（两种设备布控启停终态）、离线设备（GB 离线） */
const { chromium } = require('playwright-core');
const path = require('path');
const fs = require('fs');

const CHROME = 'C:/Users/19904/.agent-browser/browsers/chrome-152.0.7977.75/chrome.exe';
const OUT = 'C:/Users/19904/Documents/ChatGPT/sva/FWWsva/docs/evidence-phase5';
const ts = () => { const d = new Date(); const p = n => String(n).padStart(2, '0'); return `${d.getFullYear()}${p(d.getMonth()+1)}${p(d.getDate())}-${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`; };
const TS = ts();
const shots = [];
const log = m => console.log('[p5] ' + m);
const sleep = ms => new Promise(r => setTimeout(r, ms));

(async () => {
  const browser = await chromium.launch({ executablePath: CHROME, headless: true, args: ['--no-sandbox', '--disable-gpu'] });
  const page = await browser.newPage({ viewport: { width: 1720, height: 960 } });
  page.setDefaultTimeout(15000);
  const shot = async (name, note) => { await sleep(600); const f = `${name}-${TS}.png`; await page.screenshot({ path: path.join(OUT, f) }); shots.push({ name, file: f, note, url: page.url() }); log('shot ' + f + ' | ' + note); };
  const rows = async (n = 6) => await page.evaluate((nn) => {
    const rs = [...document.querySelectorAll('.el-table__body-wrapper tbody tr')].filter(r => r.offsetParent !== null);
    return { count: rs.length, texts: rs.slice(0, nn).map(r => r.innerText.replace(/\n+/g, ' | ').slice(0, 200)) };
  }, n);
  const rowButtons = async () => await page.evaluate(() => {
    const rs = [...document.querySelectorAll('.el-table__body-wrapper tbody tr')].filter(r => r.offsetParent !== null);
    return rs.slice(0, 8).map((r, i) => ({ i, btn: [...r.querySelectorAll('button')].map(b => b.textContent.trim()).join(',') }));
  });
  const clickMenu = async (level1, level2) => {
    const sub = page.locator(`.el-menu-item:visible:has-text("${level2}")`);
    if (await sub.count()) { await sub.first().click(); }
    else {
      await page.click(`.el-submenu__title:has-text("${level1}")`).catch(() => {});
      await sleep(800);
      await page.locator(`.el-menu-item:has-text("${level2}")`).first().click({ force: true }).catch(() => { throw new Error('menu not found: ' + level1 + '/' + level2); });
    }
    await sleep(1600);
  };
  const firstVisibleRowBtn = async (label) => {
    const btns = page.locator('.el-table__body-wrapper tbody tr:visible').first().locator(`button:has-text("${label}")`);
    if (await btns.count()) { await btns.first().click({ force: true }); return true; }
    return false;
  };

  try {
    await page.goto('http://localhost/#/login', { timeout: 30000 });
    await page.waitForSelector('input[placeholder="账号"]');
    await page.fill('input[placeholder="账号"]', 'admin');
    await page.fill('input[placeholder="密码"]', 'admin123');
    await page.click('button:has-text("登 录")');
    await sleep(3500);
    await page.goto('http://localhost/#/index', { timeout: 30000 });
    await page.waitForSelector('.el-submenu__title, .el-menu-item', { timeout: 15000 });
    await sleep(1200);

    // ============ A. 报警列表：ws 链路回传事件展示（场景1/2/5） ============
    await clickMenu('报警管理', '报警列表');
    await page.waitForSelector('.el-table__body-wrapper tbody tr', { timeout: 15000 });
    await sleep(1200);
    const resetBtn = page.locator('button:has-text("重置")');
    if (await resetBtn.count()) { await resetBtn.first().click(); await sleep(2000); }
    let r = await rows(8);
    log('A. list rows=' + r.count);
    r.texts.forEach((t, i) => log('A.' + i + ' ' + t));
    const hasNewRtsp = r.texts.some(t => t.includes('ev-p5-rtsp-sleep-a-20260903') || (t.includes('睡岗告警') && t.includes('模拟RTSP摄像头')));
    await shot('p5-01-alarm-list-all', `报警列表全量 rows=${r.count} ws事件最新置顶（睡岗/停留告警设备类型列）`);

    // A1. 睡岗快捷筛选 → 两条 ws 回传睡岗（RTSP + GB28181 设备类型）
    const btn = page.locator('button:has-text("睡岗快捷筛选")');
    if (await btn.count()) { await btn.first().click(); await sleep(2000); }
    r = await rows(8);
    log('A1. sleep filter rows=' + r.count);
    r.texts.forEach((t, i) => log('A1.' + i + ' ' + t));
    await shot('p5-02-sleep-filter', `睡岗快捷筛选 rows=${r.count}（期望含 RTSP 与 GB28181 两设备类型）`);

    // A2. 第一条睡岗详情（ws 回传 GB28181 睡岗，截图加载）
    const btns0 = await rowButtons();
    log('A2. row0 buttons=' + JSON.stringify(btns0[0]));
    const row0Text = await page.evaluate(() => [...document.querySelectorAll('.el-table__body-wrapper tbody tr')].filter(x => x.offsetParent !== null)[0].innerText);
    log('A2. row0=' + row0Text.replace(/\n+/g, ' | ').slice(0, 160));
    await firstVisibleRowBtn('详情');
    await sleep(2200);
    const dlgA = await page.evaluate(() => {
      const d = [...document.querySelectorAll('.el-dialog')].find(x => x.offsetParent !== null);
      if (!d) return { found: false };
      const txt = d.innerText;
      const img = d.querySelector('.el-image img, img');
      const imgOk = img ? (img.complete && img.naturalWidth > 0) : false;
      const typeLabel = [...d.querySelectorAll('.el-descriptions-item')].find(x => x.textContent.includes('设备类型'));
      return { found: true, title: (d.querySelector('.el-dialog__title') || {}).textContent || '', imgOk,
        typeText: typeLabel ? typeLabel.textContent.replace(/\n+/g, ' ').trim().slice(0, 70) : '',
        text: txt.slice(0, 500).replace(/\n+/g, ' | ') };
    });
    log('A2. detail=' + JSON.stringify(dlgA));
    await shot('p5-03-sleep-detail-1st', `详情1 设备类型=${dlgA.typeText} 截图加载=${dlgA.imgOk}`);
    await page.keyboard.press('Escape'); await sleep(900);

    // A3. 第二条睡岗详情（另一设备类型）
    const btns1 = await rowButtons();
    if (btns1[1]) {
      const row1 = page.locator('.el-table__body-wrapper tbody tr:visible').nth(1);
      const db = row1.locator('button:has-text("详情")');
      if (await db.count()) {
        await db.first().click({ force: true }); await sleep(2200);
        const dlgB = await page.evaluate(() => {
          const d = [...document.querySelectorAll('.el-dialog')].find(x => x.offsetParent !== null);
          if (!d) return { found: false };
          const txt = d.innerText;
          const img = d.querySelector('.el-image img, img');
          const imgOk = img ? (img.complete && img.naturalWidth > 0) : false;
          const typeLabel = [...d.querySelectorAll('.el-descriptions-item')].find(x => x.textContent.includes('设备类型'));
          return { found: true, imgOk, typeText: typeLabel ? typeLabel.textContent.replace(/\n+/g, ' ').trim().slice(0, 70) : '' };
        });
        log('A3. detail=' + JSON.stringify(dlgB));
        await shot('p5-04-sleep-detail-2nd', `详情2 设备类型=${dlgB.typeText} 截图加载=${dlgB.imgOk}`);
        await page.keyboard.press('Escape'); await sleep(900);
      }
    }

    // A4. 清除快捷筛选 → 全量（验证原 YOLO 停留告警回归仍在列表中）
    const clearBtn = page.locator('button:has-text("睡岗告警（筛选中）")');
    if (await clearBtn.count()) { await clearBtn.first().click(); await sleep(2500); }
    r = await rows(8);
    const dwellIdx = r.texts.findIndex(t => t.includes('停留告警') || t.includes('SVA_DWELL'));
    log('A4. after clear rows=' + r.count + ' firstDwellRow=' + dwellIdx);
    r.texts.forEach((t, i) => log('A4.' + i + ' ' + t));
    await shot('p5-05-alarm-list-dwell-regression', `清除后全量 rows=${r.count} 原YOLO停留告警在列=${dwellIdx >= 0}`);
    if (dwellIdx >= 0) {
      const rowD = page.locator('.el-table__body-wrapper tbody tr:visible').nth(dwellIdx);
      const dd = rowD.locator('button:has-text("详情")');
      if (await dd.count()) { await dd.first().click({ force: true }); await sleep(2000); await shot('p5-06-dwell-detail', '停留告警详情（YOLO 回归，截图或占位）'); await page.keyboard.press('Escape'); await sleep(800); }
    }

    // ============ B. 布控列表：两种设备布控启停终态 ============
    log('B. menu dump:');
    const menus = await page.evaluate(() => [...document.querySelectorAll('.el-submenu__title, .el-menu-item')].map(x => x.textContent.trim()).filter(t => t && t.length < 20));
    log('B. menus=' + JSON.stringify(menus));
    let deployOk = false;
    try {
      const visibleDeploy = page.locator('.el-menu-item:visible:has-text("布控列表")');
      if (await visibleDeploy.count()) {
        await visibleDeploy.first().click();
        deployOk = true;
      } else {
        const subMenu = page.locator('.el-submenu__title:visible:has-text("布控管理")');
        if (await subMenu.count()) {
          await subMenu.first().click();
          await sleep(1000);
          const kid = page.locator('.el-menu-item:visible:has-text("布控列表")');
          if (await kid.count()) { await kid.first().click(); deployOk = true; }
        }
      }
    } catch (e) { log('B. nav error: ' + e.message); }
    await sleep(2000);
    if (deployOk) {
      await page.waitForSelector('.el-table__body-wrapper tbody tr', { timeout: 12000 }).catch(() => {});
      r = await rows(10);
      log('B. deploy rows=' + r.count);
      r.texts.forEach((t, i) => log('B.' + i + ' ' + t));
      await shot('p5-07-deploy-list', `布控列表 rows=${r.count}（P5-RTSP/GB28181 睡岗布控 RUNNING + 原YOLO任务）`);
    } else { log('B. WARN 未定位布控菜单'); }

    // ============ C. 设备管理 → 离线设备：GB 幽灵流离线展示（场景3 佐证） ============
    await clickMenu('设备管理', '离线设备').catch(() => log('C. 设备管理/离线设备 导航失败'));
    await sleep(1800);
    r = await rows(6);
    log('C. lixian rows=' + r.count);
    r.texts.forEach((t, i) => log('C.' + i + ' ' + t));
    const ghostOffline = r.texts.some(t => t.includes('副井口') || t.includes('gb-ghost'));
    await shot('p5-08-lixian-gb-offline', `离线设备页 rows=${r.count} GB幽灵流离线在列=${ghostOffline}`);

    fs.writeFileSync(path.join(OUT, `p5-summary-${TS}.json`), JSON.stringify({ ts: TS, shots, menus }, null, 2), 'utf8');
    log('ALL DONE shots=' + shots.length);
  } catch (e) {
    log('ERROR: ' + e.message);
    try { await page.screenshot({ path: path.join(OUT, `p5-error-${TS}.png`) }); } catch (_) {}
  } finally {
    await browser.close();
  }
})();
