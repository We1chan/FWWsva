# easySVA D Drive Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `D:\19904\sva` the complete, runnable easySVA project location while preserving Git metadata, all user video files, and the working `Ubuntu-22.04-easySVA` WSL service environment.

**Architecture:** Stage a byte-preserving copy of the Windows project tree to the empty D-drive destination while excluding only the live WSL virtual-disk directory. Then stop the easySVA distro and use WSL's supported `--manage --move` operation so its registered VHDX is moved safely into the matching destination subtree. Validate repository identities, video hashes, WSL registration, systemd services, ports, and HTTP endpoints before treating D as authoritative; retain the C-drive tree temporarily as rollback material.

**Tech Stack:** Windows PowerShell, Robocopy, Git/Git LFS, WSL 2.3.26, Ubuntu 22.04, systemd, curl.

---

### Task 1: Record the migration baseline

**Files:**
- Create: `FWWsva/docs/superpowers/plans/2026-09-04-migrate-to-d-drive.md`
- Preserve: every video matching `*.mp4`, `*.mov`, `*.avi`, `*.mkv`, `*.webm`, `*.m4v`, `*.wmv`, or `*.flv`

- [x] **Step 1: Confirm the destination and disk capacity**

Run:

```powershell
Get-ChildItem -LiteralPath 'D:\19904\sva' -Force
Get-PSDrive -Name D
```

Expected: the destination is empty and D has more than 70 GiB free.

- [x] **Step 2: Capture repository status and remotes**

Run `git status --short --branch`, `git remote -v`, and `git log -1 --format=%H` in `FWWsva`, `SVA-backend`, `SVA-mediaServer`, `SVA-server`, and `SVA-web`.

Expected: each primary repository resolves `HEAD`; any untracked files are recorded and copied without modification.

- [x] **Step 3: Capture user-video hashes**

Run `Get-FileHash -Algorithm SHA256` for video files outside dependency caches such as `node_modules`.

Expected: a baseline list of relative paths, byte lengths, and SHA-256 hashes is available for post-copy comparison.

### Task 2: Stage the Windows project tree on D

**Files:**
- Copy: `C:\Users\19904\Documents\ChatGPT\sva\**`
- Create/update: `D:\19904\sva\**`
- Exclude from this copy only: `C:\Users\19904\Documents\ChatGPT\sva\dependencies\wsl\Ubuntu-22.04-easySVA`

- [x] **Step 1: Copy all non-VHDX project files and metadata**

Run:

```powershell
robocopy 'C:\Users\19904\Documents\ChatGPT\sva' 'D:\19904\sva' /E /COPY:DAT /DCOPY:DAT /R:2 /W:2 /XJ /XD 'C:\Users\19904\Documents\ChatGPT\sva\dependencies\wsl\Ubuntu-22.04-easySVA'
```

Expected: Robocopy exit code is 0 through 7; `.git` directories, untracked files, source, dependencies, and videos are present on D.

- [x] **Step 2: Verify the staged tree**

Run a Robocopy list-only comparison using the same exclusions, and compare repository `HEAD`, remotes, worktree status, and user-video hashes between C and D.

Expected: no missing or differing copied files; primary repository identity/status is unchanged; every user video has the same path, size, and SHA-256 hash.

### Task 3: Move the registered easySVA WSL distribution

**Files:**
- Move registration storage from: `C:\Users\19904\Documents\ChatGPT\sva\dependencies\wsl\Ubuntu-22.04-easySVA`
- Move registration storage to: `D:\19904\sva\dependencies\wsl\Ubuntu-22.04-easySVA`

- [x] **Step 1: Stop the easySVA distribution cleanly**

Run:

```powershell
wsl -d Ubuntu-22.04-easySVA -u root -- systemctl stop easysva-fake-cams easysva-rtsp-simulator easysva-rtsp-simulator-2 easysva-rtsp-simulator-3 easysva-analyzer easysva-media easysva-backend nginx redis-server mariadb
wsl --terminate Ubuntu-22.04-easySVA
```

Expected: the distribution state becomes `Stopped`.

- [x] **Step 2: Move the WSL virtual disk using the supported WSL operation**

Run:

```powershell
wsl --manage Ubuntu-22.04-easySVA --move 'D:\19904\sva\dependencies\wsl\Ubuntu-22.04-easySVA'
```

Expected: the command succeeds, registry `BasePath` points to D, and the VHDX no longer resides in the former C path.

- [x] **Step 3: Start WSL and all easySVA services**

Run the D-drive launcher or its equivalent service-start sequence, including stream restoration.

Expected: WSL starts under the same distribution name and the launcher reaches its ready state.

### Task 4: Prove the migrated service stack works

**Files:**
- Verify: `D:\19904\sva\FWWsva\启动easySVA.bat`
- Verify: WSL systemd units and HTTP endpoints

- [x] **Step 1: Verify WSL and services**

Run `wsl -l -v`, inspect the registry `BasePath`, and check `systemctl is-active` for MariaDB, Redis, nginx, backend, media server, analyzer, and fake-camera services.

Expected: `Ubuntu-22.04-easySVA` is WSL 2, its storage is on D, and required services are active.

- [x] **Step 2: Verify ports and HTTP health**

Run WSL socket checks and Windows `curl.exe` against `/`, `/prod-api/captchaImage`, and the media API endpoint used by the deployment.

Expected: nginx serves the UI, backend returns a non-error JSON response, and media service responds.

- [x] **Step 3: Re-run Git and video integrity checks on D**

Expected: all five primary repositories resolve the same commits/remotes and all preserved videos match the baseline hashes.

- [x] **Step 4: Keep rollback material until the user elects cleanup**

Do not recursively delete the old C-drive project tree during this migration run. The live WSL VHDX will already have moved to D; the remaining C tree is a recoverable source backup that can be removed after the user has used the migrated service successfully.

