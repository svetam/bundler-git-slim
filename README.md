# bundler-git-slim

[![CI](https://github.com/svetam/bundler-git-slim/actions/workflows/ci.yml/badge.svg)](https://github.com/svetam/bundler-git-slim/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/bundler-git-slim.svg)](https://rubygems.org/gems/bundler-git-slim)

Bundler plugin that slims git-installed gems down to the files listed in `spec.files`, reducing disk usage and cache size.

## Features

- Only affects gems installed from `git "..."` sources
- Only touches the copy under Bundler's `bundle_path`
- Never modifies `path` sources or your working copies
- Uses `spec.files` as an allow-list; unlisted files are removed
- Cleans up empty directories

## Installation

Add to your Gemfile:

```ruby
plugin 'bundler-git-slim'

gem 'some_gem', git: 'https://github.com/...'
```

Then run:

```bash
bundle install
```

Or install globally:

```bash
bundle plugin install bundler-git-slim
```

## Slim already-installed gems

If you have git gems already installed, run:

```bash
bundle git-slim
```

This will prune all git-sourced gems in your current bundle.

## Safety

- Scope limited to `Bundler::Source::Git`
- Only operates when `spec.full_gem_path` is inside `Bundler.bundle_path`
- If `spec.files` is empty or nil, does nothing
- Always preserves `*.gemspec` files

## Requirements

- Ruby >= 2.7
- Bundler >= 2.0

## Development

```bash
bundle install
bundle exec rake spec
bundle exec rubocop
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Create a Pull Request

## License

MIT
