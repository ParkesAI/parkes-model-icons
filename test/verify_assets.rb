# frozen_string_literal: true

require File.join(Dir.pwd, "application")
require "digest"
require "json"
require "rack/mock"
require "nokogiri"

view = ActionController::Base.new.view_context
spec = Gem.loaded_specs.fetch("parkes-model-icons")
raise "Loaded source rather than installed gem" if spec.full_gem_path.start_with?(ENV.fetch("ICON_PACKAGE_ROOT"))
source = JSON.parse(File.read(File.join(ENV.fetch("ICON_PACKAGE_ROOT"), "upstream.json")))
installed = JSON.parse(File.read(File.join(spec.full_gem_path, "upstream.json")))
raise "Missing or changed provenance" unless installed == source
%w[LICENSE NOTICE README.md CHANGELOG.md CONTRIBUTING.md docs/RELEASING.md].each do |path|
  raise "Missing #{path}" unless File.size?(File.join(spec.full_gem_path, path))
end
source.fetch("sha256").each do |path, digest|
  raise "Packaged bytes changed: #{path}" unless Digest::SHA256.file(File.join(spec.full_gem_path, path)).hexdigest == digest
end
raise "Unexpected packaged asset" unless Dir[File.join(spec.full_gem_path, "app/assets/images/**/*.svg")].size == source.fetch("icons").size
source.fetch("icons").each do |name|
  logical = "model_icons/#{name}.svg"
  url = view.model_icon_path(name)
  raise "Wrong asset path" unless url == view.image_path(logical)
  raise "Undigested asset" if url == "/assets/#{logical}"
  response = Rack::MockRequest.new(Rails.application).get(url)
  raise "Asset HTTP #{response.status}" unless response.status == 200
  raise "Wrong content type" unless response.content_type.include?("image/svg+xml")
  raise "Wrong served bytes" unless Digest::SHA256.hexdigest(response.body) == source.fetch("sha256").fetch("app/assets/images/#{logical}")

  html = view.model_icon_tag(name)
  svg = Nokogiri::HTML.fragment(html).at_css("svg")
  raise "Missing inline SVG" unless svg
  raise "Not decorative" unless svg["aria-hidden"] == "true" && svg["focusable"] == "false"
  raise "Unexpected accessible content" unless svg.css("title, desc, img").empty?
  svg.css("path").each do |path|
    raise "Not currentColor" unless (path["fill"] || svg["fill"]) == "currentColor"
  end
end
raise "Unknown should fall back" unless view.model_icon_tag("unknown").nil?
begin
  view.model_icon_path("../../LICENSE")
  raise "Path traversal accepted"
rescue Parkes::ModelIcons::UnknownIcon
  # Expected before consulting the asset pipeline.
end
puts "PASS Ruby #{RUBY_VERSION}, Rails #{Rails.version}, #{ENV.fetch('ASSET_PIPELINE', 'propshaft')}: installed gem, automatic helpers, #{source.fetch('icons').size} production digest URLs, HTTP bytes, decorative/currentColor contract and fallback"
