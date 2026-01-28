# bundler-git-slim

[![CI](https://github.com/svetam/bundler-git-slim/actions/workflows/ci.yml/badge.svg)](https://github.com/svetam/bundler-git-slim/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/bundler-git-slim.svg)](https://rubygems.org/gems/bundler-git-slim)

Bundler plugin that slims git-installed gems down to the files listed in `spec.files`, reducing disk usage and cache size.

## Why use this?

When you install gems via `git:` in your Gemfile, Bundler clones the entire repository - including specs, docs, fixtures, CI configs, and other development files that aren't part of the production gem. This bloats your bundle directory and increases Docker image sizes, especially with private gems that have large test suites or documentation.

This plugin automatically removes everything except the files declared in `spec.files`, giving you the same lean footprint as a gem installed from RubyGems.

**Use this if you:**
- Install private gems from Git repositories
- Want smaller Docker images and faster deployments
- Have git gems with large test suites, docs, or assets not needed in production

## Example output

During `bundle install`, the plugin reports what was removed:

```
Slimmed my_private_gem 1.2.0 (847 files, 12.3 MB)
```

The output shows the gem name, version, number of files removed, and total size freed.

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

- Ruby >= 3.2
- Bundler >= 2.0 (including Bundler 4.x)

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
