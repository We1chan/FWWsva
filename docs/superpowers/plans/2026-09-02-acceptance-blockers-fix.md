# Frontend/backend acceptance blockers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the frontend/backend-owned acceptance blockers and merge verified changes into each repository's `master` branch.

**Architecture:** Keep Analyzer as the source of control execution, but make a missing control on cancellation idempotent so the database can converge to `STOPPED`. Keep media URLs server-authoritative: the Vue player must never fall back to a hard-coded host. Preserve historical alarms without fabricating image data; inventory and repair only URLs whose files still exist.

**Tech Stack:** Vue 2/Jest/ESLint, Spring Boot/JUnit, MariaDB/Nginx, Git.

---

## File structure

| Path | Responsibility |
| --- | --- |
| `SVA-web/.eslintignore` | Restrict ignores to generated/root files; do not ignore source recursively. |
| `SVA-web/src/components/RTSPPlayer/index.vue` | Use only the playback URL supplied by the backend. |
| `SVA-web/tests/unit/rtsp-player.spec.js` | Regression coverage for player URL selection and missing URLs. |
| `SVA-backend/.../DeploymentAnalyzerClient.java` | Convert Analyzer's missing-control cancel response into an idempotent result. |
| `SVA-backend/.../DeploymentAnalyzerClientTest.java` | Prove the response mapping. |
| `FWWsva/deploy/scripts/reconcile-alarm-images.sh` | Safely report/rewrite only alarm URLs whose files exist. |
| `FWWsva/README.md` | Migration, GB sync, sleep-duty check, recovery and rollback instructions. |
| `FWWsva/docs/验收点2-4-前后端业务组说明.md` | Correct delivery state and record verification/remaining environment conditions. |

### Task 1: Restore a real frontend lint gate

**Files:** Modify `SVA-web/.eslintignore`; modify existing source files only when ESLint reports violations.

- [ ] Write a shell regression check before editing: `npx eslint --ext .js,.vue src` must fail with `all of the files ... are ignored`.
- [ ] Remove only the unanchored `*.js` and `*.vue` rules (and their comments) from `.eslintignore`; retain generated `build/*.js`, `src/assets`, and `public` rules.
- [ ] Run `npm run lint`; fix each reported source violation with behavior-preserving formatting/ESLint changes until it exits 0.
- [ ] Run `npm run test:unit` and `npm run build:prod`; both must exit 0.
- [ ] Commit `fix(web): restore lint gate` after verification.

### Task 2: Make analyzer cancellation idempotent

**Files:** Modify `SVA-backend/ruoyi-admin/src/main/java/com/ruoyi/web/service/deployment/DeploymentAnalyzerClient.java`; test `SVA-backend/ruoyi-admin/src/test/java/com/ruoyi/web/service/deployment/DeploymentAnalyzerClientTest.java`.

- [ ] Add a JUnit test that invokes the existing private HTTP mapping through the public cancellation path using a mocked `RestTemplate` response `{"code":0,"msg":"there is no such control"}` and asserts `AnalyzerResult.isSuccess()` with an idempotent stopped message.
- [ ] Run `mvn -pl ruoyi-admin -Dtest=DeploymentAnalyzerClientTest test`; verify that the new assertion fails because code 0 is currently mapped to failure.
- [ ] In `postJson`, after parsing the response, return `AnalyzerResult.ok("停止成功，布控已不存在", body)` exactly when `action` is `cancel`, code is 0, and normalized message is `there is no such control`; preserve every other error mapping.
- [ ] Re-run the focused test and `mvn -pl ruoyi-admin -am test -DskipITs -q`; both must pass.
- [ ] Commit `fix(backend): make analyzer cancellation idempotent` after verification.

### Task 3: Eliminate the browser hard-coded RTSP fallback

**Files:** Modify `SVA-web/src/components/RTSPPlayer/index.vue`; create `SVA-web/tests/unit/rtsp-player.spec.js`.

- [ ] Write a Jest test mounting `RTSPPlayer` with an empty `playUrl` and asserting it never creates a `ws://192.168.125.30:9117` URL and renders its unavailable state.
- [ ] Run the focused test; verify it fails against the current fallback.
- [ ] Remove the `192.168.125.30:9117/rtsp` fallback; initialize FLV only from a non-empty backend-provided HTTP/WS-FLV URL and emit/render the existing unavailable/error message otherwise.
- [ ] Run the focused test, all unit tests, lint, and production build; all must pass.
- [ ] Commit `fix(web): remove hard-coded RTSP playback fallback` after verification.

### Task 4: Reconcile recoverable historical alarm-image URLs

**Files:** Create `FWWsva/deploy/scripts/reconcile-alarm-images.sh`; modify `FWWsva/README.md` and `FWWsva/docs/验收点2-4-前后端业务组说明.md`.

- [ ] Write the script in report-only mode first: query alarm URL/id fields, map `/alarm/...` to the configured upload root, and print missing-file rows without making SQL updates.
- [ ] Run it in report-only mode in WSL and save the count; confirm it does not update the database.
- [ ] Add an explicit `--apply` branch that updates only rows whose matching file is present and whose URL needs normalization; missing files must remain unchanged and be reported as unrecoverable.
- [ ] Re-run report mode and verify that recoverable URLs return HTTP 200; record unrecoverable historical files as a data-retention limitation, while keeping the UI's existing missing-image placeholder.
- [ ] Document database migration, GB sync button/API, sleep-duty verification, control cancellation recovery, image reconciliation, and rollback instructions. Replace obsolete “待提交/待推送/待打标签” text with verified remote status.
- [ ] Commit `docs: document acceptance recovery and image reconciliation` after verification.

### Task 5: Final integration, master merge, and push

- [ ] Fetch `origin` in `FWWsva`, `SVA-backend`, and `SVA-web`; if any target `master` advanced, rebase the verified working commits and stop on conflict.
- [ ] Run `npm run lint`, `npm run test:unit`, and `npm run build:prod` in `SVA-web`; run `mvn -pl ruoyi-admin -am test -DskipITs -q` in WSL's deployed backend tree.
- [ ] Verify backend cancel API against a task whose Analyzer control is absent: response is successful and its DB task state is `STOPPED`.
- [ ] Verify direct RTSP preview through backend-provided URL and run the reconciliation report; separately record WVP/GB video prerequisites if the WVP service is unavailable.
- [ ] Merge each verified commit into its repository's `master`, push normally (never force), update/move no existing acceptance tag, and record exact commit SHAs in the delivery document.
