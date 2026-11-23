# frozen_string_literal: true

require "digest"
require "json"
require_relative "svg"

module Parkes
  module ModelIcons
    class UnknownIcon < ArgumentError; end

    NAMES = %w[aws claude nova openai].map(&:freeze).freeze
    ROOT = File.expand_path("../../..", __dir__).freeze
    MANIFEST = JSON.parse(File.read(File.join(ROOT, "upstream.json")))
    CATALOG = NAMES.to_h do |name|
      relative_path = "app/assets/images/model_icons/#{name}.svg"
      bytes = File.binread(File.join(ROOT, relative_path))
      unless Digest::SHA256.hexdigest(bytes) == MANIFEST.fetch("sha256").fetch(relative_path)
        raise ArgumentError, "Bundled icon checksum mismatch"
      end
      icon = Svg.parse(bytes).merge(asset: "model_icons/#{name}.svg".freeze).freeze
      [name, icon]
    end.freeze
    private_constant :ROOT, :MANIFEST, :CATALOG

    def self.available?(name)
      (name.is_a?(String) || name.is_a?(Symbol)) && CATALOG.key?(name.to_s)
    end

    def self.fetch(name)
      raise UnknownIcon, "Unknown model icon; use a supported name or a neutral fallback" unless available?(name)

      CATALOG.fetch(name.to_s)
    end
  end
end
