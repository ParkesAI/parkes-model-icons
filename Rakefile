# frozen_string_literal: true

require "rubygems/package"
require "rake/testtask"
require_relative "tasks/upstream"

Rake::TestTask.new do |test|
  test.pattern = "test/**/*_test.rb"
end

desc "Build the local gem; does not publish"
task :build do
  mkdir_p "pkg"
  spec = Gem::Specification.load("parkes-model-icons.gemspec")
  Gem::Package.build(spec, false, false, "pkg/#{spec.full_name}.gem")
end

desc "Test the installed package with a real production asset pipeline"
task compatibility: :build do
  Bundler.with_unbundled_env { ruby "test/compatibility.rb" }
end

namespace :upstream do
  desc "Import the pinned tarball and LICENSE from explicit local input files"
  task :import, [:tarball, :license] do |_task, args|
    Upstream.import(args.fetch(:tarball), args.fetch(:license))
  end
  desc "Check the local inventory, SVG grammar, license and checksums"
  task :check do
    Upstream.check
  end
  desc "Compare every vendored byte against the pinned remote sources"
  task :verify do
    Upstream.check(remote: true)
  end
end

task default: :test
