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

        all_paths(root).each do |path|
          next if keep.include?(path)

          if File.directory?(path) && !File.symlink?(path)
            Dir.rmdir(path) rescue nil
          else
            FileUtils.rm_f(path)
          end
        end
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
    end
  end
end

if defined?(Bundler::Plugin)
  Bundler::Plugin.add_hook("after-install") do |spec|
    next unless spec.source.is_a?(Bundler::Source::Git)

    root = Pathname(spec.full_gem_path).expand_path
    bundle_root = Bundler.bundle_path.expand_path

    next unless root.to_s.start_with?("#{bundle_root}#{File::SEPARATOR}")

    files = spec.files || []
    next if files.empty?

    Bundler::GitSlim.prune(root, files)
  end
end
