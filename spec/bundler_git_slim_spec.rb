# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BundlerGitSlim do
  describe '::VERSION' do
    it 'has a version number' do
      expect(BundlerGitSlim::VERSION).to start_with('1.0')
    end
  end

  describe '.prune' do
    let(:tmpdir) { Dir.mktmpdir('git_slim_test') }

    after { FileUtils.rm_rf(tmpdir) }

    def create_file(path, content = '')
      full_path = File.join(tmpdir, path)
      FileUtils.mkdir_p(File.dirname(full_path))
      File.write(full_path, content)
      full_path
    end

    def exists?(path)
      File.exist?(File.join(tmpdir, path))
    end

    it 'removes files not in allowed_files list' do
      create_file('lib/main.rb', '# main')
      create_file('lib/extra.rb', '# extra')
      create_file('test/test_main.rb', '# test')

      BundlerGitSlim.prune(tmpdir, ['lib/main.rb'])

      expect(exists?('lib/main.rb')).to be true
      expect(exists?('lib/extra.rb')).to be false
      expect(exists?('test/test_main.rb')).to be false
    end

    it 'removes empty directories after pruning files' do
      create_file('lib/main.rb', '# main')
      create_file('test/test_main.rb', '# test')

      BundlerGitSlim.prune(tmpdir, ['lib/main.rb'])

      expect(exists?('lib')).to be true
      expect(exists?('test')).to be false
    end

    it 'keeps ancestor directories of allowed files' do
      create_file('lib/foo/bar/baz.rb', '# baz')

      BundlerGitSlim.prune(tmpdir, ['lib/foo/bar/baz.rb'])

      expect(exists?('lib')).to be true
      expect(exists?('lib/foo')).to be true
      expect(exists?('lib/foo/bar')).to be true
      expect(exists?('lib/foo/bar/baz.rb')).to be true
    end

    it 'always preserves gemspec files' do
      create_file('mygem.gemspec', '# gemspec')
      create_file('lib/main.rb', '# main')
      create_file('extra.txt', 'extra')

      BundlerGitSlim.prune(tmpdir, ['lib/main.rb'])

      expect(exists?('mygem.gemspec')).to be true
      expect(exists?('lib/main.rb')).to be true
      expect(exists?('extra.txt')).to be false
    end

    it 'handles dotfiles' do
      create_file('.hidden', 'hidden')
      create_file('.config/settings.yml', 'settings')
      create_file('lib/main.rb', '# main')

      BundlerGitSlim.prune(tmpdir, ['lib/main.rb'])

      expect(exists?('.hidden')).to be false
      expect(exists?('.config')).to be false
      expect(exists?('lib/main.rb')).to be true
    end

    it 'removes everything except gemspecs when allowed_files is empty' do
      create_file('lib/main.rb', '# main')

      BundlerGitSlim.prune(tmpdir, [])

      expect(exists?('lib/main.rb')).to be false
    end

    it 'removes symlinks to files' do
      create_file('lib/main.rb', '# main')
      link_path = File.join(tmpdir, 'link_to_main.rb')
      File.symlink(File.join(tmpdir, 'lib/main.rb'), link_path)

      BundlerGitSlim.prune(tmpdir, ['lib/main.rb'])

      expect(exists?('lib/main.rb')).to be true
      expect(File.symlink?(link_path)).to be false
    end

    it 'removes symlinks to directories' do
      create_file('lib/main.rb', '# main')
      create_file('vendor/dep.rb', '# dep')
      link_path = File.join(tmpdir, 'vendor_link')
      File.symlink(File.join(tmpdir, 'vendor'), link_path)

      BundlerGitSlim.prune(tmpdir, ['lib/main.rb'])

      expect(exists?('lib/main.rb')).to be true
      expect(File.symlink?(link_path)).to be false
      expect(exists?('vendor')).to be false
    end

    it 'handles deeply nested structures' do
      create_file('a/b/c/d/e/f.rb', '# deep')
      create_file('a/b/x/y.rb', '# another')

      BundlerGitSlim.prune(tmpdir, ['a/b/c/d/e/f.rb'])

      expect(exists?('a/b/c/d/e/f.rb')).to be true
      expect(exists?('a/b/x')).to be false
    end

    it 'handles multiple allowed files in different directories' do
      create_file('lib/a.rb', '# a')
      create_file('lib/b.rb', '# b')
      create_file('bin/exec', '# exec')
      create_file('test/test.rb', '# test')

      BundlerGitSlim.prune(tmpdir, ['lib/a.rb', 'bin/exec'])

      expect(exists?('lib/a.rb')).to be true
      expect(exists?('lib/b.rb')).to be false
      expect(exists?('bin/exec')).to be true
      expect(exists?('test')).to be false
    end

    it 'returns count of removed files and bytes' do
      create_file('lib/main.rb', '# main')
      create_file('lib/extra.rb', '# extra')
      create_file('test/a.rb', '# a')
      create_file('test/b.rb', '# b')

      result = BundlerGitSlim.prune(tmpdir, ['lib/main.rb'])

      expect(result).to be_a(Hash)
      expect(result[:files]).to eq(3) # extra.rb, a.rb, b.rb
      expect(result[:bytes]).to be > 0
    end

    it 'returns zero counts when nothing to remove' do
      create_file('lib/main.rb', '# main')

      result = BundlerGitSlim.prune(tmpdir, ['lib/main.rb'])

      expect(result[:files]).to eq(0)
      expect(result[:bytes]).to eq(0)
    end
  end

  describe '.build_keep_set' do
    let(:tmpdir) { Dir.mktmpdir('git_slim_test') }

    after { FileUtils.rm_rf(tmpdir) }

    it 'includes all ancestor paths' do
      root = Pathname(tmpdir)
      keep = BundlerGitSlim.build_keep_set(root, ['lib/foo/bar.rb'])

      expect(keep).to include(root.join('lib/foo/bar.rb').to_s)
      expect(keep).to include(root.join('lib/foo').to_s)
      expect(keep).to include(root.join('lib').to_s)
      expect(keep).to include(root.to_s)
    end

    it 'includes gemspec files' do
      root = Pathname(tmpdir)
      gemspec_path = File.join(tmpdir, 'test.gemspec')
      File.write(gemspec_path, '# gemspec')

      keep = BundlerGitSlim.build_keep_set(root, ['lib/main.rb'])

      expect(keep).to include(gemspec_path)
    end
  end

  describe '.all_paths' do
    let(:tmpdir) { Dir.mktmpdir('git_slim_test') }

    after { FileUtils.rm_rf(tmpdir) }

    def create_file(path, content = '')
      full_path = File.join(tmpdir, path)
      FileUtils.mkdir_p(File.dirname(full_path))
      File.write(full_path, content)
    end

    it 'returns paths sorted by length descending (children before parents)' do
      create_file('a/b/c.rb', '')

      paths = BundlerGitSlim.all_paths(Pathname(tmpdir))

      c_idx = paths.index { |p| p.end_with?('c.rb') }
      b_idx = paths.index { |p| p.end_with?('/b') }
      a_idx = paths.index { |p| p.end_with?('/a') }

      expect(c_idx).to be < b_idx
      expect(b_idx).to be < a_idx
    end

    it 'excludes . and .. entries' do
      create_file('lib/main.rb', '')

      paths = BundlerGitSlim.all_paths(Pathname(tmpdir))

      expect(paths.none? { |p| File.basename(p) == '.' }).to be true
      expect(paths.none? { |p| File.basename(p) == '..' }).to be true
    end

    it 'includes dotfiles' do
      create_file('.hidden', '')
      create_file('.config/file', '')

      paths = BundlerGitSlim.all_paths(Pathname(tmpdir))

      expect(paths.any? { |p| p.end_with?('.hidden') }).to be true
      expect(paths.any? { |p| p.end_with?('.config') }).to be true
    end
  end
end
