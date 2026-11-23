# frozen_string_literal: true

require "bundler/setup"
require "minitest/autorun"
require "action_view"
require "parkes-model-icons"

class HelperTest < Minitest::Test
  def setup
    @view = ActionView::Base.empty
    @view.extend(Parkes::ModelIcons::Helper)
  end

  def test_each_mark_is_an_inline_decorative_svg_with_current_color
    Parkes::ModelIcons::NAMES.each do |name|
      html = @view.model_icon_tag(name)
      assert html.html_safe?
      svg = Nokogiri::HTML.fragment(html).at_css("svg")
      assert_equal "true", svg["aria-hidden"]
      assert_equal "false", svg["focusable"]
      assert_equal "16", svg["width"]
      assert_equal "16", svg["height"]
      assert_equal "0 0 24 24", svg["viewbox"]
      assert_empty svg.css("title, desc, img, script, style, use, image, foreignObject")
      refute_empty svg.css("path")
      svg.css("path").each { |path| assert_equal "currentColor", path["fill"] || svg["fill"] }
      assert_equal @view.model_icon_tag(name.to_sym), html
    end
  end

  def test_explicit_size_and_class
    svg = Nokogiri::HTML.fragment(@view.model_icon_tag(:nova, size: 32, css_class: "shrink-0 text-inherit")).at_css("svg")
    assert_equal "32", svg["width"]
    assert_equal "32", svg["height"]
    assert_equal "shrink-0 text-inherit", svg["class"]
  end

  def test_class_is_escaped_even_if_marked_html_safe
    hostile = %q{" onload="alert(1)"><script>bad</script>&}
    [hostile, hostile.html_safe].each do |css_class|
      html = @view.model_icon_tag(:claude, css_class: css_class)
      fragment = Nokogiri::HTML.fragment(html)
      assert_equal hostile, fragment.at_css("svg")["class"]
      assert_nil fragment.at_css("svg")["onload"]
      assert_empty fragment.css("script")
      refute_includes html, "<script>"
    end
  end

  def test_unknown_and_path_inputs_have_no_markup_and_a_strict_asset_error
    [nil, 42, {}, Object.new, "", "unknown", "bedrock", "Claude", "../claude", "/etc/passwd",
      "claude.svg", "claude\0", "%2e%2e/claude", '<svg onload="bad">', "https://example.test/x.svg"].each do |name|
      refute Parkes::ModelIcons.available?(name)
      assert_nil @view.model_icon_tag(name)
      assert_raises(Parkes::ModelIcons::UnknownIcon) { @view.model_icon_path(name) }
    end
  end

  def test_no_request_time_filesystem_reads
    File.stub(:binread, ->(*) { flunk "Render read a file" }) do
      File.stub(:read, ->(*) { flunk "Render read a file" }) do
        assert @view.model_icon_tag(:aws)
        assert_nil @view.model_icon_tag("../../LICENSE")
      end
    end
  end

  def test_options_cannot_inject_attributes_or_override_decoration
    [{ onload: "bad" }, { aria: { hidden: false } }, { title: "Claude" }, { style: "color: red" }, { path: "/tmp/x" }].each do |options|
      assert_raises(ArgumentError) { @view.model_icon_tag(:claude, **options) }
    end
    [0, -1, 1025, "16", 1.5, nil].each do |size|
      assert_raises(ArgumentError) { @view.model_icon_tag(:claude, size: size) }
    end
    assert_raises(ArgumentError) { @view.model_icon_tag(:claude, css_class: {}) }
  end

  def test_inventory_is_fixed_and_immutable
    assert_equal %w[aws claude nova openai], Parkes::ModelIcons::NAMES
    icon = Parkes::ModelIcons.fetch(:aws)
    assert_raises(FrozenError) { icon[:paths].first[:d].replace("bad") }
    assert_raises(FrozenError) { icon[:attributes][:fill] = "black" }
    assert_raises(FrozenError) { icon[:asset].replace("../../x") }
  end

  def test_asset_helper_uses_only_the_catalog_path
    @view.stub(:image_path, ->(asset) { "digested/#{asset}" }) do
      assert_equal "digested/model_icons/openai.svg", @view.model_icon_path(:openai)
    end
  end
end
