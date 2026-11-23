# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "net/http"
require "rubygems/package"
require "stringio"
require "zlib"
require_relative "../lib/parkes/model_icons/svg"

module Upstream
  ROOT = File.expand_path("..", __dir__)
  VERSION = "1.106.0"
  REVISION = "c9236c6735763f2778e7ca759488f9a486450249"
  TARBALL = "https://registry.npmjs.org/@lobehub/icons-static-svg/-/icons-static-svg-#{VERSION}.tgz"
  TARBALL_SHA256 = "fb1900cf0cfddf6a5ef947db57f951335602ad422bffff03ba9dc31390572b34"
  LICENSE_URL = "https://raw.githubusercontent.com/lobehub/lobe-icons/#{REVISION}/LICENSE"
  LICENSE_SHA256 = "add9d7531d1b21646317a8958e38fc727506fa39d24bdecb44154d943c82753a"
  NAMES = %w[aws claude nova openai].freeze

  def self.download(url)
    uri = URI(url)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 15, read_timeout: 30) do |http|
      http.get(uri.request_uri)
    end
    raise "Download failed: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    response.body
  end

  def self.files(tarball, license)
    raise "Tarball checksum mismatch" unless Digest::SHA256.hexdigest(tarball) == TARBALL_SHA256
    raise "License checksum mismatch" unless Digest::SHA256.hexdigest(license) == LICENSE_SHA256

    expected = NAMES.to_h { |name| ["package/icons/#{name}.svg", "app/assets/images/model_icons/#{name}.svg"] }
    expected["package/package.json"] = "vendor/upstream/package.json"
    files = { "vendor/upstream/LICENSE" => license }
    Zlib::GzipReader.wrap(StringIO.new(tarball)) do |gzip|
      Gem::Package::TarReader.new(gzip) do |tar|
        tar.each do |entry|
          destination = expected[entry.full_name]
          next unless destination
          raise "Unexpected archive entry" unless entry.file? && !files.key?(destination)

          files[destination] = entry.read
        end
      end
    end
    raise "Incomplete upstream inventory" unless files.size == expected.size + 1
    metadata = JSON.parse(files.fetch("vendor/upstream/package.json"))
    raise "Package identity/license changed" unless metadata.values_at("name", "version", "license") == ["@lobehub/icons-static-svg", VERSION, "MIT"]
    files.each { |path, bytes| Parkes::ModelIcons::Svg.parse(bytes) if path.end_with?(".svg") }
    files
  end

  def self.manifest(files)
    {
      "package" => "@lobehub/icons-static-svg", "version" => VERSION,
      "repository" => "https://github.com/lobehub/lobe-icons", "revision" => REVISION,
      "revision_source" => "npm registry gitHead for version #{VERSION}",
      "tarball" => TARBALL, "tarball_sha256" => TARBALL_SHA256,
      "license_url" => LICENSE_URL, "license" => "MIT",
      "icons" => NAMES, "sha256" => files.sort.to_h.transform_values { |bytes| Digest::SHA256.hexdigest(bytes) }
    }
  end

  def self.import(tarball_path, license_path)
    files = files(File.binread(tarball_path), File.binread(license_path))
    files.each do |path, bytes|
      destination = File.join(ROOT, path)
      FileUtils.mkdir_p(File.dirname(destination))
      File.binwrite(destination, bytes)
    end
    File.write(File.join(ROOT, "upstream.json"), JSON.pretty_generate(manifest(files)) + "\n")
    check
  end

  def self.check(remote: false)
    recorded = JSON.parse(File.read(File.join(ROOT, "upstream.json")))
    paths = NAMES.map { |name| "app/assets/images/model_icons/#{name}.svg" } + %w[vendor/upstream/LICENSE vendor/upstream/package.json]
    local = paths.to_h { |path| [path, File.binread(File.join(ROOT, path))] }
    raise "Provenance mismatch" unless manifest(local) == recorded
    raise "Unexpected shipped icons" unless Dir[File.join(ROOT, "app/assets/images/**/*.svg")].sort == paths.grep(/\.svg\z/).map { |path| File.join(ROOT, path) }.sort
    raise "License changed" unless Digest::SHA256.hexdigest(local.fetch("vendor/upstream/LICENSE")) == LICENSE_SHA256
    local.each { |path, bytes| Parkes::ModelIcons::Svg.parse(bytes) if path.end_with?(".svg") }
    if remote
      original = files(download(TARBALL), download(LICENSE_URL))
      raise "Vendored bytes differ from pinned upstream" unless local == original
    end
    puts "PASS upstream: #{NAMES.size} vetted mono SVGs, MIT license, package metadata and checksums#{remote ? ', verified against pinned upstream bytes' : ''}"
  end
end
