# Live Output Endpoint Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use inline execution with the approved design and verify each task before moving on.

**Goal:** Add the Analyzer API and runtime lifecycle needed to switch annotated algorithm video output on and off for a running deployment.

**Architecture:** A thin HTTP handler parses and validates the backend contract, delegates lookup to Scheduler, and lets Worker replace the per-control AvPushStream while holding the existing runtime mutex used by frame publication. Existing detection and overlay code remains the single source of annotated frames.

**Tech Stack:** C++17, libevent HTTP, JsonCpp, OpenCV/FFmpeg, CMake/CTest.

---

### Task 1: Lock down request validation

**Files:**
- Create: `SVA-server/Analyzer/Core/LiveOutput.h`
- Create: `SVA-server/tests/LiveOutputContractTest.cpp`
- Modify: `SVA-server/CMakeLists.txt`

- [x] Write the failing contract test for valid requests, missing `controlCode`, missing `pushStreamUrl` when video is enabled, and video-disabled requests.
- [x] Verify the test cannot build before the parser exists. The local Windows shell lacks JsonCpp headers; the expected failure is a missing `json/json.h`/parser build dependency, not a passing test.
- [x] Implement the inline parser with defaults and range validation.
- [ ] Run `cmake --build build-gpu --target LiveOutputContractTest` and `ctest --test-dir build-gpu -R LiveOutputContractTest` in the Linux/WSL build environment.

### Task 2: Add runtime output switching

**Files:**
- Modify: `SVA-server/Analyzer/Core/Worker.h`
- Modify: `SVA-server/Analyzer/Core/Worker.cpp`
- Modify: `SVA-server/Analyzer/Core/Scheduler.h`
- Modify: `SVA-server/Analyzer/Core/Scheduler.cpp`

- [x] Add `Worker::updateControlOutput` to locate a running control, update websocket event settings, stop and join an old encoder, and create/connect a replacement `AvPushStream` for video output.
- [x] Keep the existing mutex boundary around frame processing so stream replacement cannot race with `addVideoFrame`.
- [x] Add the Scheduler delegation and clear errors for unknown controls or failed push-stream connections.
- [ ] Build the Analyzer target and run the existing CTest suite.

### Task 3: Expose the HTTP endpoint

**Files:**
- Modify: `SVA-server/Analyzer/Core/Server.h`
- Modify: `SVA-server/Analyzer/Core/Server.cpp`

- [x] Register `/api/control/live-output` and advertise it from `/`.
- [x] Parse the JSON contract, return HTTP 400 for invalid input, HTTP 500 for runtime failures, and `code=1000` for success.
- [ ] Start the rebuilt Analyzer and verify the root route lists `live-output`; verify a valid request reaches runtime validation instead of returning 404.

### Task 4: Final verification

- [ ] Run `git diff --check` in both repositories.
- [ ] Run focused CTest plus existing web/backend contract tests where their dependencies are available.
- [ ] Confirm the running service binary is rebuilt/restarted; source changes alone do not alter the already-running old 9993 process.
