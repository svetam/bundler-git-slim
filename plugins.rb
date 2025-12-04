# frozen_string_literal: true

require 'bundler/plugin/api'
require_relative 'lib/bundler_git_slim'

Bundler::Plugin.add_hook('after-install') do |spec_install|
  # Unwrap SpecInstallation if needed
  spec = spec_install.respond_to?(:spec) ? spec_install.spec : spec_install

  result = BundlerGitSlim.prune_spec(spec)
  next unless result&.dig(:files)&.positive?

  size = BundlerGitSlim.format_bytes(result[:bytes])
  Bundler.ui.warn "Slimmed #{spec.name} #{spec.version} (#{result[:files]} files, #{size})"
end

class GitSlimCommand < Bundler::Plugin::API
  command 'git-slim'

  def exec(_command, _args)
    Bundler.ui.info 'Slimming installed git gems...'
    specs = git_specs
    return Bundler.ui.info('No git-sourced gems found.') if specs.empty?

    totals = prune_all(specs)
    report_totals(totals)
  end

  private

  def git_specs
    Bundler.load.specs.select { |s| s.source.is_a?(Bundler::Source::Git) }
  end

  def prune_all(specs)
    totals = { files: 0, bytes: 0 }

    specs.each do |spec|
      result = BundlerGitSlim.prune_spec(spec)
      next unless result&.dig(:files)&.positive?

      totals[:files] += result[:files]
      totals[:bytes] += result[:bytes]
      size = BundlerGitSlim.format_bytes(result[:bytes])
      Bundler.ui.warn "Slimmed #{spec.name} #{spec.version} (#{result[:files]} files, #{size})"
    end

    totals
  end

  def report_totals(totals)
    if totals[:files].zero?
      Bundler.ui.info 'All git gems already slim.'
    else
      size = BundlerGitSlim.format_bytes(totals[:bytes])
      Bundler.ui.warn "Done. Removed #{totals[:files]} files (#{size}) total."
    end
  end
end
