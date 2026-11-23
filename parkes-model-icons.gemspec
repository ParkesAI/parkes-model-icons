# frozen_string_literal: true

require_relative "lib/parkes/model_icons/version"

Gem::Specification.new do |spec|
  spec.name = "parkes-model-icons"
  spec.version = Parkes::ModelIcons::VERSION
  spec.authors = ["Parkes contributors"]
  spec.summary = "Self-hosted model provider logos for Rails"
  spec.description = "Selected Lobe Icons SVGs with safe, decorative, currentColor Rails helpers and asset pipeline support."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"
  spec.files = Dir["lib/**/*.rb", "app/assets/**/*.{svg,js}", "vendor/upstream/*", "upstream.json", "LICENSE", "NOTICE", "README.md", "CHANGELOG.md", "CONTRIBUTING.md", "docs/*.md"].sort
  spec.require_paths = ["lib"]
  spec.homepage = "https://github.com/ParkesAI/parkes-model-icons"
  spec.metadata = {
    "source_code_uri" => spec.homepage,
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }
  spec.add_dependency "railties", ">= 7.2", "< 8.2"
  spec.add_dependency "actionview", ">= 7.2", "< 8.2"
  spec.add_dependency "nokogiri", ">= 1.15", "< 2"
end
