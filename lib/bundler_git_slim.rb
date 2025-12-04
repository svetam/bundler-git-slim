# frozen_string_literal: true

require 'fileutils'
require 'set'
require 'pathname'

module BundlerGitSlim
  VERSION = '0.1.0'
  UNITS = %w[B KB MB GB].freeze

  class << self
    def format_bytes(bytes)
      return '0 B' if bytes.zero?

      exp = (Math.log(bytes) / Math.log(1024)).to_i
      exp = [exp, UNITS.size - 1].min
      format('%<size>.1f %<unit>s', size: bytes.to_f / (1024**exp), unit: UNITS[exp])
    end

    def prune(root, allowed_files)
      root = Pathname(root).expand_path
      keep = build_keep_set(root, allowed_files)
      removed_files = 0
      removed_bytes = 0

      all_paths(root).each do |path|
        next if keep.include?(path)

        if File.directory?(path) && !File.symlink?(path)
          begin
            Dir.rmdir(path)
          rescue SystemCallError
            # Directory not empty
          end
        else
          removed_bytes += File.size(path) if File.exist?(path)
          FileUtils.rm_f(path)
          removed_files += 1
        end
      end

      { files: removed_files, bytes: removed_bytes }
    end

    def build_keep_set(root, allowed_files)
      keep = Set.new

      allowed_files.each do |rel|
        path = root.join(rel).cleanpath
        keep << path.to_s
        path.ascend { |p| keep << p.to_s }
      end

      Dir.glob(root.join('*.gemspec')).each { |gs| keep << File.expand_path(gs) }

      keep
    end

    def all_paths(root)
      Dir.glob(root.join('**/*'), File::FNM_DOTMATCH)
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
