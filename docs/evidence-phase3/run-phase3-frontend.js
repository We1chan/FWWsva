/* phase3 step3：设备管理页各场景截图取证 */
const { chromium } = require('playwright-core');
const path = require('path');
const fs = require('fs');

const CHROME = 'C:/Users/19904/.agent-browser/browsers/chrome-152.0.7977.75/chrome.exe';
const OUT = 'C:/Users/19904/Documents/ChatGPT/sva/FWWsva/docs/evidence-phase3';
const ts = () => { const d = new Date(); const p = n => String(n).padStart(2, '0'); return `${d.getFullYear()}${p(d.getMonth()+1)}${p(d.getDate())}-${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`; };
const TS = ts();
const shots = []; // 每场景摘要
const log = m => console.log('[step3] ' + m);
const sleep = ms => new Promise(r => setTimeout(r, ms));

(async () => {
  const browser = await chromium.launch({ executablePath: CHROME, headless: true, args: ['--no-sandbox', '--disable-gpu'] });
  const page = await browser.newPage({ viewport: { width: 1600, height: 950 } });
  page.setDefaultTimeout(15000);

  const shot = async (name, note) => {
    await sleep(400);
    const f = `${name}-${TS}.png`;
    await page.screenshot({ path: path.join(OUT, f) });
    shots.push({ name, file: f, note, url: page.url() });
    log(`shot ${f} @ ${page.url()}`);
  };
  const tableRows = async () => {
    return await page.evaluate(() => {
      const rows = [...document.querySelectorAll('.el-table__body-wrapper tbody tr')].filter(r => r.offsetParent !== null);
      const first = rows[0] ? rows[0].innerText.split('\n').slice(0, 12).join(' | ') : '(none)';
      return { count: rows.length, first };
    });
  };
  const clickRowBtn = async (rowIdx, btnText) => {
    const rows = page.locator('.el-table__body-wrapper tbody tr:visible');
    const row = rows.nth(rowIdx);
    await row.hover();
    await sleep(400);
    await row.locator(`button:has-text("${btnText}")`).first().click({ force: true });
    await sleep(1600);
  };

  const closeDialog = async () => {
    await page.keyboard.press('Escape');
    await sleep(900);
    // 兜底点右上角关闭
    const still = await page.evaluate(() => !!([...document.querySelectorAll('.el-dialog__wrapper')].find(x => x.offsetParent !== null && getComputedStyle(x).display !== 'none')));
    if (still) {
      await page.locator('.el-dialog__wrapper:visible .el-dialog__headerbtn').first().click({ force: true }).catch(() => {});
      await sleep(800);
    }
  };

  const clickMenu = async (level1, level2) => {
    const sub = page.locator(`.el-menu-item:visible:has-text("${level2}")`);
    if (await sub.count()) {
      await sub.first().click();
    } else {
      await page.click(`.el-submenu__title:has-text("${level1}")`);
      await sleep(700);
      await page.locator(`.el-menu-item:has-text("${level2}")`).first().click({ force: true });
    }
    await sleep(1200);
  };

  try {
    // --- 登录 ---
    await page.goto('http://localhost/#/login', { timeout: 30000 });
    await page.waitForSelector('input[placeholder="账号"]');
    await page.fill('input[placeholder="账号"]', 'admin');
    await page.fill('input[placeholder="密码"]', 'admin123');
    await page.click('button:has-text("登 录")');
    await sleep(3500);

    // --- 进入后台布局 ---
    await page.goto('http://localhost/#/index', { timeout: 30000 });
    await page.waitForSelector('.el-submenu__title', { timeout: 15000 });
    await sleep(1000);

    // --- 进入 设备管理/设备管理 ---
    await clickMenu('设备管理', '设备管理');
    await page.waitForSelector('.el-table__body-wrapper tbody tr', { timeout: 15000 });
    await sleep(800);
    let r = await tableRows();
    log(`manage rows=${r.count} first="${r.first}"`);

    // a. 全列表（含接入类型列）
    await shot('p3-10-list-all', `设备管理全列表 rows=${r.count}`);

    // b. 按"接入类型=GB28181"筛选
    await page.locator('.el-form-item', { hasText: '接入类型' }).locator('.el-select').click();
    await sleep(700);
    await page.click('.el-select-dropdown__item:visible:has-text("GB28181")');
    await sleep(1500);
    r = await tableRows();
    await shot('p3-11-filter-gb28181', `接入类型=GB28181 筛选后 rows=${r.count}`);
    const filterText = await page.evaluate(() => document.body.innerText.match(/共\s*\d+\s*条|total[\s\S]{0,20}/)?.[0] || '');
    log(`filter total hint="${filterText}"`);

    // 清回全部：点筛选重置（查询区"重置"按钮或清除下拉）
    await page.click('button:has-text("重置")').catch(() => {});
    await sleep(1200);

    // c. 点"同步国标设备"
    await page.click('button:has-text("同步国标设备")');
    await sleep(2500);
    const toast = await page.evaluate(() => {
      const m = document.querySelector('.el-message, .el-message__content, .el-notification');
      return m ? m.textContent.trim().slice(0, 120) : '(no toast)';
    });
    log('sync toast=' + toast);
    await shot('p3-12-sync-gb', `同步国标设备 toast="${toast}"`);

    // d. GB28181 设备行 → 修改（只读国标信息）
    // 先找到接入类型列为 GB28181 的行
    const gbRowIdx = await page.evaluate(() => {
      const rows = [...document.querySelectorAll('.el-table__body-wrapper tbody tr')].filter(r => r.offsetParent !== null);
      for (let i = 0; i < rows.length; i++) {
        if (/GB28181|国标/.test(rows[i].innerText) && !/RTSP/.test(rows[i].innerText)) return i;
      }
      return -1;
    });
    log('gb row idx=' + gbRowIdx);
    if (gbRowIdx >= 0) {
      await clickRowBtn(gbRowIdx, '修改');
      // 对话框（append-to-body 到 body）
      const dlg = await page.evaluate(() => {
        const d = [...document.querySelectorAll('.el-dialog')].find(x => x.offsetParent !== null);
        if (!d) return { found: false };
        const txt = d.innerText;
        const hasVideoUrlInput = !!d.querySelector('input[placeholder*="视频流"]');
        const gbFields = ['platformId', 'deviceId', 'channelId'].map(k => d.querySelector(`input[data-key="${k}"]`)?.value).filter(Boolean);
        return {
          found: true,
          hasSection: txt.includes('国标信息'),
          hasChannel: txt.includes('3402000000131') || txt.includes('34020000001'),
          hasVideoUrlInput,
          gbValues: gbFields,
          text: txt.slice(0, 600).replace(/\n+/g, ' | ')
        };
      });
      log('gb dialog=' + JSON.stringify(dlg));
      await shot('p3-13-edit-gb28181', `GB28181 修改对话框 found=${dlg.found} 国标信息=${dlg.hasSection} 无视频流输入=${!dlg.hasVideoUrlInput}`);
      await closeDialog();
    }

    // e. RTSP 行 → 修改（有视频流地址，回归）
    const rtspRowIdx = await page.evaluate(() => {
      const rows = [...document.querySelectorAll('.el-table__body-wrapper tbody tr')].filter(r => r.offsetParent !== null);
      for (let i = 0; i < rows.length; i++) {
        if (/rtsp:\/\//i.test(rows[i].innerText) || /RTSP/.test(rows[i].innerText)) return i;
      }
      return -1;
    });
    log('rtsp row idx=' + rtspRowIdx);
    if (rtspRowIdx >= 0) {
      await clickRowBtn(rtspRowIdx, '修改');
      const dlg2 = await page.evaluate(() => {
        const d = [...document.querySelectorAll('.el-dialog')].find(x => x.offsetParent !== null);
        if (!d) return { found: false };
        return { found: true, hasVideoUrlInput: !!d.querySelector('input[placeholder*="视频流"]'), text: d.innerText.slice(0, 300).replace(/\n+/g, ' | ') };
      });
      log('rtsp dialog=' + JSON.stringify(dlg2));
      await shot('p3-14-edit-rtsp', `RTSP 修改对话框 有视频流输入=${dlg2.hasVideoUrlInput}`);
      await closeDialog();
    }

    // f. 新增对话框（默认 RTSP）
    await page.click('button:has-text("新增")').catch(() => {});
    await sleep(1200);    const addDlg = await page.evaluate(() => {
      const d = [...document.querySelectorAll('.el-dialog')].find(x => x.offsetParent !== null);
      if (!d) return { found: false };
      const typeItem = [...d.querySelectorAll('.el-form-item')].find(x => (x.querySelector('.el-form-item__label')?.textContent || '').includes('接入类型'));
      return {
        found: true,
        deviceTypeVal: typeItem ? (typeItem.querySelector('input')?.value || '') : '',
        hasVideoUrlInput: !!d.querySelector('input[placeholder*="视频流"]'),
        hasGbSection: d.innerText.includes('国标信息')
      };
    });
    log('add dialog=' + JSON.stringify(addDlg));
    await shot('p3-15-add-rtsp', `新增对话框 接入类型=${addDlg.deviceTypeVal} 有视频流=${addDlg.hasVideoUrlInput} 无国标=${!addDlg.hasGbSection}`);
    await closeDialog();

    // g. 实时监控页
    await clickMenu('设备管理', '实时监控');
    await page.waitForSelector('.el-table__body-wrapper tbody tr', { timeout: 15000 }).catch(() => {});
    await sleep(1000);
    await shot('p3-16-realtime', '实时监控页');
    log('realtime rows=' + JSON.stringify(await tableRows()));

    // h. 离线设备页
    await clickMenu('设备管理', '离线设备');
    await sleep(1200);
    await shot('p3-17-lixian', '离线设备页');

    // i. 回到设备管理 → 预览 GB28181（点击预览视频，弹窗出现播放器即取证）
    await clickMenu('设备管理', '设备管理');
    await page.waitForSelector('.el-table__body-wrapper tbody tr', { timeout: 15000 });
    await sleep(800);
    const gbRow2 = await page.evaluate(() => {
      const rows = [...document.querySelectorAll('.el-table__body-wrapper tbody tr')].filter(r => r.offsetParent !== null);
      for (let i = 0; i < rows.length; i++) if (/GB28181|国标/.test(rows[i].innerText) && !/RTSP/.test(rows[i].innerText)) return i;
      return -1;
    });
    if (gbRow2 >= 0) {
      await clickRowBtn(gbRow2, '预览视频');
      await sleep(2500);
      const preview = await page.evaluate(() => {
        const d = [...document.querySelectorAll('.el-dialog')].find(x => x.offsetParent !== null);
        const hasVideo = !!document.querySelector('.el-dialog video, video');
        const hasPlayer = !!document.querySelector('.el-dialog .vjs-player, .el-dialog #monitor-player, .el-dialog canvas, video');
        return { dialogOpen: !!d, hasVideo, hasPlayer, bodyHasFlv: /flv|monitor|player/i.test(document.body.innerText) };
      });
      log('preview=' + JSON.stringify(preview));
      await shot('p3-18-preview-gb28181', `GB28181 预览弹窗 dialog=${preview.dialogOpen} player=${preview.hasPlayer}`);
      await closeDialog();
    }

    // 摘要
    fs.writeFileSync(path.join(OUT, `p3-summary-${TS}.json`), JSON.stringify({ ts: TS, shots }, null, 2), 'utf8');
    log('ALL DONE shots=' + shots.length);
  } catch (e) {
    log('ERROR: ' + e.message);
  } finally {
    await browser.close();
  }
})();
