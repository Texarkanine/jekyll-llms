# Tech Context

Ruby gem for Jekyll 4.x that emits LLM-oriented text artifacts during site build. Runtime dependency and packaging live in `jekyll-llms.gemspec`; version in `lib/jekyll/llms/version.rb`.

## Environment Setup

- Ruby `>= 3.0` (see gemspec).
- `bundle install` from the repo root.

## Build Tools

- Bundler + RubyGems (`jekyll-llms.gemspec`, `Gemfile` if present).
- Rake tasks in `Rakefile` (`rake test` is the default).

## Testing Process

- Minitest suite under `test/`, run via `bundle exec rake test` (also enforces 100% line coverage via SimpleCov — see `AGENTS.md`).
- Mutation testing with Mutant: `bundle exec mutant run` (config in `config/mutant.yml`). Prefer `--fail-fast` while iterating.
- Working rules for coverage/mutants: `AGENTS.md`.
