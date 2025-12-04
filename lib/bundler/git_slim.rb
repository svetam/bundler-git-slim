# frozen_string_literal: true

require "fileutils"
require "set"
require "pathname"

module Bundler
  module GitSlim
    VERSION = "0.1.0"

    class << self
      def prune(root, allowed_files)
        root = Pathname(root).expand_path
        keep = build_keep_set(root, allowed_files)
        removed_files = 0
        removed_dirs = 0

        all_paths(root).each do |path|
          next if keep.include?(path)

          if File.directory?(path) && !File.symlink?(path)
            begin
              Dir.rmdir(path)
              removed_dirs += 1
            rescue SystemCallError
              # Directory not empty, skip
            end
          else
            FileUtils.rm_f(path)
            removed_files += 1
          end
        end

        { files: removed_files, dirs: removed_dirs }
      end

      def build_keep_set(root, allowed_files)
        keep = Set.new

        allowed_files.each do |rel|
          path = root.join(rel).cleanpath
          keep << path.to_s
          path.ascend { |p| keep << p.to_s }
        end

        Dir.glob(root.join("*.gemspec")).each { |gs| keep << File.expand_path(gs) }

        keep
      end

      def all_paths(root)
        Dir.glob(root.join("**/*"), File::FNM_DOTMATCH)
           .map { |p| File.expand_path(p) }
           .reject { |p| %w[. ..].include?(File.basename(p)) }
           .sort_by(&:length)
           .reverse
      end

      def prune_spec(spec)
        return nil unless spec.source.is_a?(Bundler::Source::Git)

        root = Pathname(spec.full_gem_path).expand_path
        bundle_root = Bundler.bundle_path.expand_path

        return nil unless root.to_s.start_with?("#{bundle_root}#{File::SEPARATOR}")

        files = spec.files || []
        return nil if files.empty?

        prune(root, files)
      end
    end
  end
end

if defined?(Bundler::Plugin)
  Bundler::Plugin.add_hook("after-install") do |spec|
    result = Bundler::GitSlim.prune_spec(spec)
    next unless result

    total = result[:files] + result[:dirs]
    if total > 0
      Bundler.ui.info "  git-slim: removed #{result[:files]} files, #{result[:dirs]} dirs"
    end
  end

  class Bundler::GitSlim::Command < Bundler::Plugin::API
    command "git-slim"

    def exec(_command, _args)
      Bundler.ui.info "Slimming installed git gems..."

      specs = Bundler.load.specs.select { |s| s.source.is_a?(Bundler::Source::Git) }

      if specs.empty?
        Bundler.ui.info "No git-sourced gems found."
        return
      end

      total_files = 0
      total_dirs = 0

      specs.each do |spec|
        result = Bundler::GitSlim.prune_spec(spec)
        next unless result

        removed = result[:files] + result[:dirs]
        next if removed.zero?

        total_files += result[:files]
        total_dirs += result[:dirs]
        Bundler.ui.info "  #{spec.name}: removed #{result[:files]} files, #{result[:dirs]} dirs"
      end

      if total_files.zero? && total_dirs.zero?
        Bundler.ui.info "All git gems already slim."
      else
        Bundler.ui.info "Done. Removed #{total_files} files, #{total_dirs} dirs total."
      end
    end
  end
end
