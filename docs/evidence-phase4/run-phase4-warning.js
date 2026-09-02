/* 阶段4 E2E：睡岗告警页取证（快捷筛选 / 设备类型列 / 类型标签 / 详情截图与缺图占位） */
const { chromium } = require('playwright-core');
const path = require('path');
const fs = require('fs');

const CHROME = 'C:/Users/19904/.agent-browser/browsers/chrome-152.0.7977.75/chrome.exe';
const OUT = 'C:/Users/19904/Documents/ChatGPT/sva/FWWsva/docs/evidence-phase4';
const ts = () => { const d = new Date(); const p = n => String(n).padStart(2, '0'); return `${d.getFullYear()}${p(d.getMonth()+1)}${p(d.getDate())}-${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`; };
const TS = ts();
const shots = [];
const log = m => console.log('[p4] ' + m);
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
  const tableRows = async () => {
    return await page.evaluate(() => {
      const rows = [...document.querySelectorAll('.el-table__body-wrapper tbody tr')].filter(r => r.offsetParent !== null);
      return { count: rows.length, texts: rows.slice(0, 5).map(r => r.innerText.replace(/\n+/g, ' | ')) };
    });
  };
  const clickMenu = async (level1, level2) => {
    const sub = page.locator(`.el-menu-item:visible:has-text("${level2}")`);
    if (await sub.count()) { await sub.first().click(); }
    else {
      await page.click(`.el-submenu__title:has-text("${level1}")`);
      await sleep(700);
      await page.locator(`.el-menu-item:has-text("${level2}")`).first().click({ force: true });
    }
    await sleep(1500);
  };
  const getToast = async () => page.evaluate(() => {
    const m = document.querySelector('.el-message, .el-message__content, .el-notification');
    return m ? m.textContent.trim().slice(0, 120) : '(no toast)';
  });

  try {
    // --- 登录 ---
    await page.goto('http://localhost/#/login', { timeout: 30000 });
    await page.waitForSelector('input[placeholder="账号"]');
    await page.fill('input[placeholder="账号"]', 'admin');
    await page.fill('input[placeholder="密码"]', 'admin123');
    await page.click('button:has-text("登 录")');
    await sleep(3500);
    await page.goto('http://localhost/#/index', { timeout: 30000 });
    await page.waitForSelector('.el-submenu__title', { timeout: 15000 });
    await sleep(1000);

    // --- 报警管理 / 报警列表 ---
    await clickMenu('报警管理', '报警列表');
    await page.waitForSelector('.el-table__body-wrapper tbody tr', { timeout: 15000 });
    await sleep(1200);
    // 先点"重置"清空任何默认过滤，确保 a 段为真正全列表
    const resetBtn = page.locator('button:has-text("重置")');
    if (await resetBtn.count()) { await resetBtn.first().click(); await sleep(1800); }

    // a. 全列表：报警类型标签 + 设备类型列 + 睡岗快捷筛选按钮可见
    let r = await tableRows();
    log(`a. list rows=${r.count} (after reset)`);
    log('a. first=' + JSON.stringify(r.texts[0]));
    await shot('p4-01-list-all', `报警列表全列表 rows=${r.count} 含报警类型标签列/设备类型列`);

    // b. 点击"睡岗快捷筛选" → 仅睡岗告警
    const btn = page.locator('button:has-text("睡岗快捷筛选")');
    if (await btn.count()) { await btn.first().click(); await sleep(1800); }
    else log('WARN 未找到睡岗快捷筛选按钮');
    r = await tableRows();
    log(`b. after shortcut rows=${r.count}`);
    r.texts.slice(0, 3).forEach(t => log('b. row=' + t.slice(0, 220)));
    await shot('p4-02-filter-sleep-duty', `睡岗快捷筛选后 rows=${r.count}（报警类型标签+设备类型列）`);
    const activeBtn = await page.evaluate(() => document.body.innerText.includes('睡岗告警（筛选中）'));
    log('b. shortcut active label 筛选中=' + activeBtn);

    // c. 打开 GB28181 睡岗行详情（应带截图 + 设备类型 GB28181 tag）
    const detailRowBtn = page.locator('.el-table__body-wrapper tbody tr:visible').first().locator('button:has-text("查看详情")');
    await detailRowBtn.first().click({ force: true });
    await sleep(2000);
    const dlgA = await page.evaluate(() => {
      const d = [...document.querySelectorAll('.el-dialog')].find(x => x.offsetParent !== null);
      if (!d) return { found: false };
      const txt = d.innerText;
      const img = d.querySelector('.el-image img');
      const imgOk = img ? (img.complete && img.naturalWidth > 0) : false;
      const typeLabel = [...d.querySelectorAll('.el-descriptions-item')].find(x => x.textContent.includes('设备类型'));
      return {
        found: true, title: (d.querySelector('.el-dialog__title') || {}).textContent || '',
        hasGBTag: !!typeLabel && /GB28181/.test(typeLabel.textContent),
        imgOk, hasPlaceholder: txt.includes('暂无抓拍') || txt.includes('抓拍图加载失败'),
        typeText: typeLabel ? typeLabel.textContent.replace(/\n+/g, ' ').trim().slice(0, 60) : '',
        text: txt.slice(0, 420).replace(/\n+/g, ' | ')
      };
    });
    log('c. GB28181 detail=' + JSON.stringify(dlgA));
    await shot('p4-03-detail-gb28181', `GB28181睡岗详情 设备类型=${dlgA.typeText} 截图加载=${dlgA.imgOk}`);
    await page.keyboard.press('Escape');
    await sleep(1000);

    // d. 打开 RTSP 睡岗行详情（无图 → "暂无抓拍"占位）
    const rtspRowIdx = await page.evaluate(() => {
      const rows = [...document.querySelectorAll('.el-table__body-wrapper tbody tr')].filter(r => r.offsetParent !== null);
      for (let i = 0; i < rows.length; i++) if (/模拟RTSP摄像头|dev_mock_camera_001/.test(rows[i].innerText) && !/RTSP/.test(rows[i].innerText) === false && rows[i].innerText.includes('RTSP')) return i;
      // 备选：包含 RTSP 设备类型 tag 且不在第一行
      for (let i = 0; i < rows.length; i++) if (rows[i].innerText.includes('RTSP') && rows[i].innerText.includes('模拟RTSP摄像头')) return i;
      return -1;
    });
    log('d. rtsp row idx=' + rtspRowIdx);
    if (rtspRowIdx >= 0) {
      const rows = page.locator('.el-table__body-wrapper tbody tr:visible');
      await rows.nth(rtspRowIdx).locator('button:has-text("查看详情")').first().click({ force: true });
      await sleep(2000);
      const dlgB = await page.evaluate(() => {
        const d = [...document.querySelectorAll('.el-dialog')].find(x => x.offsetParent !== null);
        if (!d) return { found: false };
        const txt = d.innerText;
        const typeLabel = [...d.querySelectorAll('.el-descriptions-item')].find(x => x.textContent.includes('设备类型'));
        return {
          found: true,
          hasRTSPTag: !!typeLabel && /RTSP/.test(typeLabel.textContent),
          typeText: typeLabel ? typeLabel.textContent.replace(/\n+/g, ' ').trim().slice(0, 60) : '',
          hasNoSnapPlaceholder: txt.includes('暂无抓拍'),
          hasFailPlaceholder: txt.includes('抓拍图加载失败'),
          hasImg: !!d.querySelector('.el-image img')
        };
      });
      log('d. RTSP detail=' + JSON.stringify(dlgB));
      await shot('p4-04-detail-rtsp-no-snapshot', `RTSP睡岗详情 设备类型=${dlgB.typeText} 暂无抓拍=${dlgB.hasNoSnapPlaceholder}`);
    } else { log('WARN 未定位 RTSP 睡岗行'); }

    await page.keyboard.press('Escape');
    await sleep(800);

    // e. 清空筛选回到全列表（验证快捷筛选清除按钮）
    const clearBtn = page.locator('button:has-text("睡岗告警（筛选中）")');
    if (await clearBtn.count()) { await clearBtn.first().click(); await sleep(3000); }
    r = await tableRows();
    log(`e. after clear rows=${r.count}`);
    await shot('p4-05-clear-shortcut', `清除快捷筛选后 rows=${r.count}（期望全列表 ≥10）`);

    fs.writeFileSync(path.join(OUT, `p4-summary-${TS}.json`), JSON.stringify({ ts: TS, shots }, null, 2), 'utf8');
    log('ALL DONE shots=' + shots.length);
  } catch (e) {
    log('ERROR: ' + e.message);
  } finally {
    await browser.close();
  }
})();
