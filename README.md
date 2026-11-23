# Parkes Model Icons

Self-hosted provider logos for Rails. Four vetted monochrome marks from
[Lobe Icons](https://github.com/lobehub/lobe-icons): `aws`, `claude`, `nova`, `openai`.
No JavaScript build, CDN, runtime network request or provider-name resolver is needed.

**Status:** 0.1.0 is an unreleased source candidate, not published to RubyGems.
Use an exact reviewed source revision or local checkout until a release is available.

## Installation

Requires Ruby 3.2+ and Rails 7.2–8.1. Use a Ruby version supported by your Rails version
(Rails 8 requires Ruby 3.2+, Rails 8.1 requires Ruby 3.2+ as declared by the installed framework;
check your selected Rails release). Development CI pairs are listed in `ci/github-actions.yml`.

For a local checkout, use a path dependency (replace the example path):

```ruby
gem "parkes-model-icons", path: "../parkes-model-icons"
```

Run `bundle install`. Rails loads the engine and helpers automatically.
For an approved `.gem` artifact, verify its supplied SHA256, run
`gem install ./parkes-model-icons-0.1.0.gem --local`, then use
`gem "parkes-model-icons", "0.1.0"` and `bundle install --local` in an environment
where the declared Rails dependencies are installed. This does not publish anything.

## Theme-aware rendering

```erb
<%= model_icon_tag :claude %>
<%= model_icon_tag :nova, size: 16, css_class: "shrink-0" %>
```

`model_icon_tag(name, size: 16, css_class: nil)` returns an inline SVG or `nil` for an
unknown name. Exact lowercase strings and symbols are accepted; there is no alias,
case conversion or path interpretation. `size` is an integer from 1 to 1024, applied
to width and height. `css_class` is a string or nil and is always attribute-escaped,
even when the string was marked HTML-safe. Other keyword arguments are rejected.

All paths use `currentColor`; set `color` on the surrounding text/container in each
theme. Keep the icon from shrinking with the application's layout class. The helper
preserves the artwork's viewBox and paths, but removes upstream title, inline style
and original dimensions. It constructs elements with Rails tag helpers, not raw
caller-supplied SVG. Only fixed, checksummed bundled files are loaded, once at boot.

### Unknown names

```erb
<% if Parkes::ModelIcons.available?(logo_name) %>
  <%= model_icon_tag logo_name, css_class: "shrink-0" %>
<% else %>
  <%# Render your application's neutral decorative icon here. %>
<% end %>
```

The equivalent `model_icon_tag(logo_name) || your_neutral_icon` composition also works.
The gem intentionally does not guess providers, resolve model identifiers or choose
another provider's logo. The consuming app owns that mapping and its neutral fallback.
`Parkes::ModelIcons::NAMES` lists the supported keys. `available?` returns false for
unsupported names and input types. `fetch` is a strict immutable catalog lookup and
raises `Parkes::ModelIcons::UnknownIcon < ArgumentError` on unsupported input.

### Accessibility

These helpers render **decorative icons only**: `aria-hidden="true"`,
`focusable="false"`, no title, alt text, role or tab stop. Put the provider/model name
in visible text next to the icon. Do not use the icon alone as a control label.
The helper deliberately does not permit arbitrary attributes or accessibility overrides.

## Asset pipelines

The inline helper works without asset precompilation. Original, byte-identical SVG
files are also available as Rails assets for other consumers:

```erb
<%= model_icon_path :openai %>
```

This uses the pipeline's digested URL. Unknown names raise `UnknownIcon` before
asking the pipeline; caller-supplied filesystem paths are never opened.

**Propshaft:** no additional setup.

**Sprockets 4:** add this to the application's `app/assets/config/manifest.js`:

```js
//= link parkes_model_icons.js
```

Or link only the assets you need, such as `//= link model_icons/claude.svg`.

Do not render the path in an `<img>` when the logo must match text colour: external
SVG images cannot inherit the surrounding page's `color`. Use `model_icon_tag` for
light/dark themes. Direct assets retain upstream titles; the inline helper is the
specified decorative rendering path.

## Development and provenance

```sh
bundle install
bundle exec ruby -Ilib -e 'ARGV.each { |file| require_relative file }' test/helper_test.rb test/svg_test.rb
bundle exec rake upstream:verify
ASSET_PIPELINE=propshaft bundle exec rake compatibility
ASSET_PIPELINE=sprockets bundle exec rake compatibility
```

The compatibility test builds and installs the package into an isolated gem home,
boots a small production Rails app, precompiles assets and verifies actual HTTP
response bytes. It never needs the Console database. `RAILS_VERSION` selects the
framework constraint; install that bundle before running its compatibility test.

See [CONTRIBUTING](CONTRIBUTING.md), [release preparation](docs/RELEASING.md),
[provenance](upstream.json) and [CHANGELOG](CHANGELOG.md). The CI configuration is
currently a template under `ci/`, not an installed/green GitHub workflow.

## Licensing

The Rails wrapper is [MIT](LICENSE). Artwork is MIT as declared by LobeHub;
[its complete copyright and permission notice](vendor/upstream/LICENSE) is shipped
unchanged, including Copyright (c) 2023 LobeHub. The npm tarball contains no LICENSE,
so this notice is pinned to the package's registry `gitHead` revision. The gem vendors
only the four selected files, not all 998 upstream SVGs. See [NOTICE](NOTICE) for
attribution and the trademark disclaimer. Software licensing does not grant rights
to the depicted brands or imply endorsement.
