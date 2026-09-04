# live-output endpoint design

## Goal

Restore server-side algorithm preview for deployments by implementing the Analyzer
`POST /api/control/live-output` endpoint expected by the Java backend and web UI.
Successful video-enabled requests must reuse the existing analyzer control and
publish annotated frames to the configured push stream. If Analyzer cannot provide
the output, the web UI may continue to use the device preview as a compatibility
fallback.

## Architecture and data flow

1. The web UI calls `POST /deployments/{id}/live-output`.
2. The Java backend resolves the deployment's SVA binding, builds the analyzer
   input and output stream URLs, and calls Analyzer on its configured port.
3. Analyzer validates the request and reuses the existing Control/Scheduler
   lifecycle used by `/api/control/add` and `/api/control/cancel`.
4. When video output is enabled, the analyzer writes detection overlays to the
   configured push stream; the backend returns the corresponding algorithm stream
   URL to the UI.

## API contract

`POST /api/control/live-output` accepts JSON fields:

- `controlCode` (required): deployment/control identifier.
- `videoEnabled` (optional boolean, default false).
- `liveEventEnabled` (optional boolean, default false).
- `wsEventFps` (optional number, default 8; valid range `(0, 30]`).
- `pushStreamUrl` (required when `videoEnabled=true`).

The endpoint returns JSON with an explicit success/error status and a useful
message. Invalid input produces a client error; control or stream setup failures
produce a server-side error. Disabling video must not create a new media output.

## Compatibility and error handling

The endpoint is additive and does not change existing add/cancel routes. Repeated
requests for the same `controlCode` are idempotent where the existing control
implementation permits it. The UI's existing raw-device-preview fallback remains
in place for older Analyzer binaries or transient failures.

## Testing

Add a regression test that exercises the route contract and proves it is no longer
reported as HTTP 404. Cover validation of the required control code and the
video-disabled path. Run the focused Analyzer tests and the existing web/backend
contract tests.
