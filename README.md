# bundler-git-slim

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

## Safety

- Scope limited to `Bundler::Source::Git`
- Only operates when `spec.full_gem_path` is inside `Bundler.bundle_path`
- If `spec.files` is empty or nil, does nothing
- Always preserves `*.gemspec` files

## License

MIT
