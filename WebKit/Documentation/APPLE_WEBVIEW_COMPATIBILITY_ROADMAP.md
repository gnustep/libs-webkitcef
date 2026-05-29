# Apple WebView Compatibility Gap Checklist and Roadmap

## Purpose

This document maps the current GNUstep WebKit interface to the legacy Apple WebKit1 `WebView` compatibility goal, and proposes an implementation plan focused on practical source and runtime compatibility.

Scope:

- Public API compatibility for existing Objective-C applications that previously used Apple `WebView`
- Behavioral compatibility for commonly used navigation, delegate, and JavaScript flows
- Clear separation between public compatibility API and CEF-specific internals

## Current Baseline

Current public interface is defined in:

- `WebKit/WebView.h`

Current implementation is primarily in:

- `WebKit/WebView.mm`

Observed current state:

- A compact, working API exists for loading content, navigation, and basic JavaScript execution.
- Internal callback methods are exposed in the public header.
- Delegate-based compatibility surface (Apple-style) is largely absent.
- Companion WebKit1 classes/protocols typically expected by old clients are not yet present.

## Compatibility Levels

Use these levels to define completion:

- Level 1: Build compatibility
- Existing code compiles with minimal or no changes.

- Level 2: Core runtime compatibility
- Navigation, history, load lifecycle, and basic callbacks behave as expected for common apps.

- Level 3: Ecosystem compatibility
- Delegate matrix, companion classes, notifications, and policy/UI behavior closely match legacy WebKit1 usage patterns.

## Gap Checklist

### A. Public Header Surface

Status: Partial

Needed:

- Remove or hide implementation-internal callbacks from public API.
- Add missing Apple-style public methods/properties on `WebView`.
- Add missing notification constants and dictionary keys as stable public symbols.
- Match expected Objective-C nullability/ownership conventions for public methods.

Deliverable:

- Public header that is compatibility-oriented, with internals moved to private headers or class extensions.

### B. Delegate Model Parity

Status: Missing/Minimal

Needed:

- Introduce Apple-style delegate entry points:
- Frame load lifecycle delegate behavior
- Policy decision delegate behavior
- UI delegate behavior (window creation, JavaScript dialogs, status text, etc.)
- Resource load delegate behavior (as feasible)

- Ensure delegate callback ordering and threading semantics are documented and testable.

Deliverable:

- Working delegate properties and callback dispatch paths, with compatibility tests.

### C. Companion Types and Objects

Status: Missing

Needed:

- Provide compatibility types commonly used with legacy `WebView` code paths (for example frame-level objects, history list objects, preferences-like configuration surfaces, scripting bridge hooks where feasible).
- Ensure type names and basic method contracts satisfy compile-time expectations.

Deliverable:

- Minimal viable companion class set for high-value compatibility scenarios.

### D. JavaScript API Semantics

Status: Partial

Needed:

- Define and implement compatibility behavior for synchronous string evaluation expectations.
- Clarify asynchronous pathways and callback ordering.
- Ensure errors/results map consistently to legacy caller expectations.

Deliverable:

- Documented and tested behavior contract for JS execution methods.

### E. Navigation and Windowing Semantics

Status: Partial

Needed:

- Align popup/new-window, target frame, and history behavior with legacy expectations where practical.
- Add policy delegate hooks before final navigation decisions.
- Standardize redirect and load-failure behavior surface.

Deliverable:

- Stable navigation lifecycle contract with test coverage.

### F. Notifications and Event Ordering

Status: Partial

Needed:

- Expand notification set and payloads to compatibility-friendly forms.
- Ensure deterministic event ordering for start/commit/finish/fail style transitions.

Deliverable:

- Notification matrix with ordering guarantees and tests.

### G. Error and Policy Mapping

Status: Partial

Needed:

- Normalize error domains/codes and policy outcomes to expected app-facing contracts.
- Ensure cancellation, blocked content, and invalid URL cases are predictable.

Deliverable:

- Error mapping specification and conformance tests.

### H. API Hygiene and Internal Encapsulation

Status: Needs Work

Needed:

- Keep CEF-specific process/bootstrap hooks separate from WebView compatibility surface.
- Move internal-only callbacks out of public header.
- Keep public header focused on compatibility API only.

Deliverable:

- Clean public/private boundary reducing future compatibility regressions.

## Phase Plan

## Phase 1: Build Compatibility First

Goal:

- Maximize compile success for apps expecting legacy `WebView` signatures.

Work:

- Refactor `WebKit/WebView.h` into compatibility-first public API.
- Move internal callbacks to private declarations.
- Add placeholder implementations for missing high-frequency methods and properties.
- Add minimal companion class stubs to satisfy imports and linking.

Exit criteria:

- Representative legacy sample apps compile without API edits.

## Phase 2: Core Runtime Behavior

Goal:

- Make core browsing flows behave like legacy expectations for common app patterns.

Work:

- Implement delegate plumbing for frame load and policy decisions.
- Align navigation lifecycle events and history behavior.
- Improve JavaScript result and error semantics.
- Add compatibility notifications and payloads.

Exit criteria:

- Core compatibility tests pass for load, navigate, policy, and JS scenarios.

## Phase 3: Advanced Delegate and UI Compatibility

Goal:

- Support broader application behaviors requiring UI and resource delegate surfaces.

Work:

- Implement UI delegate flows (new windows, dialogs, status text).
- Implement resource-related delegate callbacks where feasible with CEF.
- Expand companion types beyond minimal stubs.

Exit criteria:

- Advanced app samples behave correctly with expected delegate interactions.

## Phase 4: Hardening and Documentation

Goal:

- Stabilize compatibility and make it maintainable.

Work:

- Add regression suite and CI checks for compatibility APIs and behavior.
- Document supported vs intentionally unsupported legacy behaviors.
- Add migration notes for edge cases where exact parity is not possible with CEF architecture.

Exit criteria:

- Compatibility matrix published and test-gated in CI.

## Suggested File-Level Work Items

- `WebKit/WebView.h`
- Convert to compatibility-focused public declaration.

- `WebKit/WebView.mm`
- Implement delegate/property/event behavior and compatibility adapters.

- `WebKit/WebKit.h`
- Keep process bootstrap helpers, but avoid leaking internals into compatibility API.

- `WebKit/Documentation/`
- Add a compatibility matrix doc and per-phase status updates.

## Test Matrix (Minimum)

- API compile test against representative legacy headers/usages
- Basic URL load and HTML load
- Back/forward and canGoBack/canGoForward behavior
- Redirect and error flows
- Policy decision callback timing
- Popup/new-window handling
- JavaScript execution success and error cases
- Notification emission and ordering

## Risks and Constraints

- Exact one-to-one runtime behavior with historical Apple WebKit1 may not always be possible due to architectural differences between legacy WebKit1 internals and CEF.
- Compatibility should prioritize common app usage first, then edge behavior.
- Public API stability should be treated as a strict contract once Phase 1 is complete.

## Recommended Next Step

Start Phase 1 by creating a "compatibility target header" checklist directly against `WebKit/WebView.h`, then implement missing members in descending order of app usage frequency.
