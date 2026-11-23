# Contributing

Keep the collection small and reviewable. The current API supplies four selected
monochrome marks, not the full upstream catalog. Provider/model resolution and
neutral fallback artwork belong to the consuming application.

## Checks

Use the Ruby/Rails combinations in `ci/github-actions.yml`. Run `bundle install`,
then the explicit helper/SVG tests and both installed-package compatibility commands
from README. For a targeted change, select its test file; configured CI is responsible
for the supported matrix. New source should use frozen string literals and existing
Ruby/Rails conventions. Do not run a whole consuming-application suite for packaging
changes without a specific diagnostic reason.

Add tests for any changed input/output or failure contract. Preserve the path boundary,
attribute escaping, fixed decorative accessibility and `currentColor` behavior. Never
accept user-provided SVG, asset paths, arbitrary attributes or external resources.

## Upstream files

Do not edit SVGs or license files by hand. `tasks/upstream.rb` pins the npm tarball,
source revision, MIT license and selected names. To reproduce the current import:

1. Download the exact tarball and LICENSE URLs in `upstream.json` into temporary files.
2. Run `bundle exec rake 'upstream:import[/absolute/package.tgz,/absolute/LICENSE]'`.
3. Run `bundle exec rake upstream:verify` and the selected tests. The importer checks
   the input hashes before extraction and allows only the fixed inventory. It writes
   only the expected files; unexpected existing SVGs fail verification rather than
   being silently deleted.

For an upgrade, review upstream source/license changes, update the pinned values and
selected inventory deliberately, reproduce assets, inspect the SVG grammar and retain
checksums. A new SVG grammar is a security-relevant code change, not a reason to relax
validation until an import passes. Unknown key behavior is public API; adding/removing
keys or changing return values must be documented. Keep original source bytes intact
(no line-ending normalization), especially `vendor/upstream/LICENSE`.

## Submission and publication

Use an independently reviewed change and require current-candidate CI before release.
Local test success is not independent review. Do not commit local Gemfile.lock,
.bundle, pkg, tmp, credential files or downloaded reference tarballs. A release must
use the packaged gem and its checksum, not an unversioned copy of the source directory.
See `docs/RELEASING.md` for the remaining owner-controlled publication steps.
