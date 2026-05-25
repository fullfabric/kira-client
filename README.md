# kira-client

A small Ruby client for [Kira Talent](https://www.kiratalent.com/)'s v2 API. Wraps the applicant and webhook endpoints we use from FullFabric's backend.

## Installation

In your `Gemfile`:

```ruby
gem 'kira-client', '~> 3.0', git: 'https://github.com/fullfabric/kira-client.git', tag: 'v3.0.0', require: 'kira'
```

Then `bundle install`.

Requires Ruby >= 3.0.

## Usage

Construct a client once with your Kira API token; reach resources through accessors that mirror Kira's URL hierarchy.

```ruby
client = Kira::V2::Client.new(token: ENV.fetch('KIRA_TOKEN'))

interview = client.interview('your-interview-id')
```

### Create an applicant

```ruby
applicant = interview.applicants.create(
  first_name: 'Peter',
  last_name:  'Pan',
  email:      'peter@example.com',
  external_id: 'your-internal-id'   # optional; echoed back in the response
)

applicant['check_in_page_url']   # => "https://app.kiratalent.com/applicant/.../check-in"
applicant['external_id']         # => "your-internal-id"
```

### List applicants

```ruby
# All applicants registered against the interview (single page).
interview.applicants.list
# => [{ "uid" => "...", "email" => "...", "check_in_page_url" => "...", ... }, ...]

# Filter to the applicant registered under a specific email (returns a 0- or 1-element array).
interview.applicants.list(email: 'peter@example.com')
```

### Fetch a single applicant

```ruby
applicant = interview.applicants.get('uid-from-kira')
applicant['check_in_page_url']
```

Use this when recovering from a `Kira::ApplicantError::Exists` — the error's `parsed['detail']` carries the existing applicant's `uid`.

### List webhooks

```ruby
interview.webhooks.list
# => [{ "uid" => "...", "endpoint" => "...", "event_subscriptions" => [...], "active" => true }, ...]
```

### Create a webhook

```ruby
webhook = interview.webhooks.create(
  endpoint:            'https://your-app.example.com/kira/callback',
  event_subscriptions: ['applicant.interview_completed'],
  secret:              ENV.fetch('KIRA_WEBHOOK_SECRET'),
  active:              true   # default
)

webhook['uid']
```

### Delete a webhook

```ruby
interview.webhooks.delete(uid)   # returns nil on 204
```

## Configuration

### Token

Required. Pass on every `Client.new` call.

```ruby
Kira::V2::Client.new(token: '...')
```

### Base URL

Optional. Defaults to `https://app.kiratalent.com/api`. Override for a Kira sandbox, regional endpoint, or a stub server.

```ruby
Kira::V2::Client.new(token: '...', base_url: 'https://app.staging.kiratalent.com/api')
```

## Error handling

Every operation raises `Kira::Error` (or a subclass) on a non-2xx response. The exception carries the HTTP status and the response body.

```ruby
begin
  interview.applicants.create(...)
rescue Kira::ApplicantError::Exists => e
  # 409 Conflict — applicant with that email already registered
  e.status  # => 409
  e.parsed  # => { "detail" => "This email address has already been registered to ..." }
rescue Kira::Error => e
  e.status  # => Integer HTTP status (4xx or 5xx)
  e.body    # => String, raw response body
  e.parsed  # => Hash if Kira returned JSON, nil otherwise
end
```

Network errors (timeouts, connection refused) propagate as `Faraday::Error` subclasses — not wrapped, so callers can match on Faraday's own exception types.

## Testing

The gem's own specs run offline against [VCR](https://github.com/vcr/vcr) cassettes recorded once against a Kira test interview. Cassettes scrub the real token and webhook secret via `filter_sensitive_data` — committed cassettes contain placeholder strings like `<KIRA_TOKEN>`.

```bash
bundle exec rspec
```

### Re-recording cassettes

Set the credentials in env vars and delete the affected cassette file:

```bash
export KIRA_INTERVIEW_ID=... KIRA_TOKEN=... KIRA_SECRET=...
rm spec/cassettes/applicant/create_success.yml
bundle exec rspec spec/lib/kira/v2/applicants_spec.rb
```

`record: :once` is the default — VCR records when no cassette exists and replays when one does. Cassettes pinned with `record: :none` (currently the 5xx and the webhook DELETE cases) are hand-crafted and can't be re-recorded automatically.

## License

MIT
