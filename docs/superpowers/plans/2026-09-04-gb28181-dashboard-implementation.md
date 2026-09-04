# GB28181 Simulator and Dashboard Implementation Plan

> **For agentic workers:** Execute the checklist task-by-task with verification after each phase.

**Goal:** Deploy a complete local GB28181 software-simulator path while preserving real-device support, and redesign the dashboard side panels for clear, accurate, high-tech visualization.

**Architecture:** Keep WVP and a dedicated GB ZLMediaKit isolated from the existing RTSP/media plane. The backend owns directory synchronization and controlled playback, while Analyzer consumes the resulting stream and the frontend displays algorithm output. Dashboard components retain existing APIs but receive a shared visual token system and compact data-first layouts.

**Tech Stack:** Spring Boot/RuoYi backend, WVP Java service, ZLMediaKit, SVA Analyzer, Vue 2 + Element UI + ECharts/DataV, systemd, Playwright.

---

### Task 1: Reconcile deployment assets and prerequisites

**Files:**
- Inspect: `FWWsva/install_source.sh`, `FWWsva/deploy/systemd/easysva-wvp.service`, `SVA-backend/deploy/gb28181/scripts/health.sh`
- Runtime targets: `/opt/SVA/wvp/wvp-pro.jar`, `/opt/SVA/gb28181/wvp.yml`, `/etc/systemd/system/easysva-wvp.service`

- [ ] Confirm WVP jar, config, database and GB ZLMediaKit binary exist before starting protocol services.
- [ ] If assets are present, install units and environment file with 0600 permissions; if absent, report the exact missing artifact and do not pretend GB is active.
- [ ] Start MariaDB/Redis, GB media, WVP, backend and simulator in dependency order.
- [ ] Run `easysva-gb-health` and capture WVP, SIP, ZLM and backend results.

### Task 2: Verify backend GB28181 contracts

**Files:**
- Inspect: `SVA-backend/ruoyi-admin/src/main/java/com/ruoyi/waring/controller/HDeviceController.java`
- Inspect: `SVA-backend/ruoyi-admin/src/main/java/com/ruoyi/waring/service/impl/Gb28181SyncServiceImpl.java`
- Test: `SVA-backend/ruoyi-admin/src/test/java/com/ruoyi/waring/service/impl/Gb28181SyncServiceImplTest.java`

- [ ] Run backend GB regression tests and verify pagination, idempotent channel IDs, offline handling and WVP failure behavior.
- [ ] Call authenticated `/waring/device/gb28181/sync` only after WVP is healthy.
- [ ] Verify `/waring/device/list` contains GB28181 channel rows with stable IDs and online state.
- [ ] Verify start/stop/preview APIs produce and release WVP/ZLM sessions for one simulator channel.

### Task 3: Redesign dashboard side panels

**Files:**
- Modify: `SVA-web/src/views/dping/index.vue`
- Modify: `SVA-web/src/views/dping/components/monitoring-points.vue`
- Modify: `SVA-web/src/views/dping/components/warning-summary.vue`
- Modify: `SVA-web/src/views/dping/components/total-summary.vue`
- Modify: `SVA-web/src/views/dping/components/warning-rank.vue`
- Modify: `SVA-web/src/views/dping/components/warning-growth.vue`
- Test: browser visual regression via Playwright at 1920x1080 and reduced-motion mode

- [ ] Add scoped design tokens for deep-blue glass panels, cyan/amber status colors, readable typography and restrained glow.
- [ ] Replace oversized decorative gauges with compact status cards and a labeled treatment donut.
- [ ] Replace right-side ranking chart with horizontal ranking bars and resilient long-label handling.
- [ ] Align growth cards into month/quarter/year rows and growth/treatment columns with explicit signs and units.
- [ ] Keep existing API fields, route targets and responsive scale container unchanged.

### Task 4: Build, deploy and verify frontend

**Files:**
- Build output: `SVA-web/dist/`
- Runtime target: `/var/www/SVA-web/dist/`

- [ ] Run `npm run lint` and `npm run build:prod`.
- [ ] Publish the build to nginx static root and reload nginx after `nginx -t`.
- [ ] Use Playwright to login, visit dashboard and every dynamic leaf route, collect failed requests and console errors.
- [ ] Verify safe controls (search/reset/refresh/layout switching) and algorithm-output preview behavior.

### Task 5: End-to-end evidence and remote synchronization

- [ ] Capture service states, Analyzer health metrics, WVP health, simulator registration and continuous FLV byte counts.
- [ ] Run `git diff --check` and repository tests; remove temporary test artifacts.
- [ ] Commit each logical repository change with Conventional Commit messages.
- [ ] Push `SVA-server`, `SVA-backend`, `SVA-web` and `FWWsva` to their configured remotes; record commit IDs and push results.
