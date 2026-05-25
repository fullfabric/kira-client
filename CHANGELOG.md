# Changelog

## 3.1.0 — 2026-05-25

### Added

- `Kira::V2::Applicants#list(email: nil)` — fetch the applicants registered against an interview. Pass `email:` to filter to the (single) applicant registered under that address, otherwise returns the first page of all applicants. The email value is URL-encoded; `+` (which Kira parses as a space when unescaped) is handled.
- `Kira::V2::Applicants#get(uid)` — fetch a single applicant by their Kira `uid`. Returns the same shape as the entries in `#list`, including `check_in_page_url`. Raises `Kira::Error` with status 404 if the uid is unknown.

Both endpoints exist on Kira's v2 API; they were just absent from the gem's surface.

## 3.0.0 — 2026-05-12

**Breaking change.** The per-resource classes are gone; everything reaches through one client.

### Migration

Before (2.x):

```ruby
applicant_service = Kira::V2::Applicant.new(interview_id, token)
applicant_service.create(first_name: ..., last_name: ..., email: ...)

interview_service = Kira::V2::Interview.new(interview_id, token, secret)
interview_service.create(endpoint: ..., event_subscriptions: ['applicant.interview_completed'])
```

After (3.0):

```ruby
client = Kira::V2::Client.new(token: token)
interview = client.interview(interview_id)

interview.applicants.create(first_name: ..., last_name: ..., email: ...)
interview.webhooks.create(endpoint: ..., event_subscriptions: [...], secret: secret)
```

### What changed

- New `Kira::V2::Client.new(token:, base_url: nil)` is the only entry point.
- New `Kira::V2::Webhooks#list`, `#create`, `#delete` — previously the only webhook surface was `Kira::V2::Interview#create`, which misleadingly created a webhook (not an interview).
- `webhooks.create` no longer does a GET-then-POST idempotency check. The previous heuristic ignored the endpoint URL and would silently skip creating a correct webhook when a stale one existed. Callers that want idempotency: `webhooks.list` first, then conditionally `create`.
- `webhooks.create(secret:)` is now a method kwarg (was a constructor arg on the old `Interview` class).
- `Kira::Error` now exposes `status`, `body`, and `parsed` readers.
- `Kira::ApplicantError::Exists` is raised for 409 "already registered" responses (was always `Kira::Error` previously).

### Removed

- `Kira::V2::Applicant` class.
- `Kira::V2::Interview` class (the one that created webhooks). The new `Kira::V2::Interview` is a per-id accessor, not a service.
- `Kira::V2::Client` module (used internally in 2.x for shared HTTP plumbing). The new `Kira::V2::Client` is a class.

## 2.0.0 — 2020-10-27

Initial release supporting Kira v2 API: applicant creation and webhook registration.

### Subsequent commits without a version bump

- SQ2-1048 (2026-05) — Replaced live-API specs with VCR cassettes; dropped hardcoded credentials from the repo.
- SQ2-1050 (2026-05) — Hardened error handling: `Kira::Error` carries HTTP status/body, JSON parse failures no longer leak `JSON::ParserError`, `Kira::ApplicantError::Exists` raised for 409s. DRYed shared Faraday plumbing into a mixin.
- SQ2-1052 (2026-05) — Added `base_url:` kwarg to both 2.x constructors.
- SQ2-1047 (2026-05) — Bumped Faraday floor to `~> 2.13` to close the SSRF advisory (GHSA-q3m6-9hgw-2g66).
- SQ2-1046 (2026-05) — Bumped Ruby to 3.0.7 in CI; dropped unmaintained dev dependencies (`spork`, `binding_of_caller`, `better_errors`, etc.); declared `contracts` and `faraday` as runtime dependencies in the gemspec.
- SQ2-534 (2024) — Bumped Rack to address a security advisory.
- Pre-1.0 commits — initial implementation and CI setup.
