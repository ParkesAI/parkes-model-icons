# frozen_string_literal: true

require "bundler/setup"
require "minitest/autorun"
require_relative "../lib/parkes/model_icons/svg"
require_relative "../tasks/upstream"

class SvgTest < Minitest::Test
  def setup
    @svg = File.binread(File.expand_path("../app/assets/images/model_icons/claude.svg", __dir__))
  end

  def test_preserves_shapes_and_omits_title_style_and_original_size
    result = Parkes::ModelIcons::Svg.parse(@svg)
    assert_equal "currentColor", result[:attributes][:fill]
    assert_equal Nokogiri::XML(@svg).at_xpath("//*[local-name()='path']")["d"], result[:paths].first[:d]
    refute result[:attributes].key?(:style)
    refute result[:attributes].key?(:width)
  end

  def test_rejects_active_content_entities_namespaces_and_fixed_colors
    bad = [
      @svg.sub("<title>", '<script>alert(1)</script><title>'),
      @svg.sub("<path ", '<path onload="bad" '),
      @svg.sub("<path ", '<path href="https://example.test/x" '),
      @svg.sub("<path ", '<path style="fill:black" '),
      @svg.sub('fill="currentColor"', 'fill="black"'),
      @svg.sub("</svg>", '<image href="https://example.test/x"/></svg>'),
      @svg.sub("</svg>", '<foreignObject><p>bad</p></foreignObject></svg>'),
      @svg.sub("<path ", '<path xmlns="https://example.test" '),
      @svg.sub("<svg ", '<svg xmlns:x="https://example.test" '),
      '<!DOCTYPE svg [<!ENTITY secret SYSTEM "file:///etc/passwd">]>' + @svg,
      '<?xml-stylesheet href="https://example.test/x"?>' + @svg,
      @svg.sub("</svg>", "</broken>"),
      @svg.sub(/d="[^"]+"/, 'd="url(https://example.test)"'),
      @svg.sub(/<path.*?<\/path>/, "")
    ]
    bad.each { |bytes| assert_raises(ArgumentError) { Parkes::ModelIcons::Svg.parse(bytes) } }
  end

  def test_offline_provenance
    assert Upstream.check.nil?
  end

  def test_import_rejects_unpinned_bytes_before_extracting
    assert_raises(RuntimeError) { Upstream.files("not a tarball", "not a license") }
  end
end
