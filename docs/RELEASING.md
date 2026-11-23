# Release preparation

## Current boundary

0.1.0 is an unreleased local candidate. No remote repository, release tag or RubyGems
publication is created by these commands. No `push`/`release` Rake task or publishing
workflow exists. Creation of a public repository, pushing code, merging and publishing
a package each require their applicable owner authorization.

## Before remote review

1. Confirm access to `https://github.com/ParkesAI/parkes-model-icons` and the
   applicable source-push authorization. The gemspec identifies that repository;
   the URLs become browsable source only after an authorized push.
2. Install the reviewed workflow template `ci/github-actions.yml` as the repository's
   `.github/workflows/ci.yml` through an authorized interface. It is not active while
   retained under `ci/`. Do not claim it ran from local checks. Configure protected
   branches and review rules at the approved repository; no automation bypasses them.
3. Add normal ignore rules for `.bundle/`, `Gemfile.lock`, `pkg/`, `tmp/` and `*.gem`;
   preserve SVG/upstream license bytes with `.gitattributes` `-text` rules. Confirm
   these policies are installed before release.
4. Push only the reviewed task source and record the full candidate/base SHA. Hand off
   that exact revision to an independent reviewer. Revalidate affected evidence after
   any source/metadata change; never infer approval from a successful build.

## Build and verify

1. Update version and changelog on the authorized release candidate. Run the explicit
   tests, pinned upstream verification, and required supported-runtime CI matrix.
2. Run `bundle exec rake build`; inspect `gem specification pkg/parkes-model-icons-VERSION.gem files`.
   The package must contain the helpers, engine, all four SVGs, manifest, MIT wrapper
   license, NOTICE and complete upstream license/metadata. It must not contain local
   dependencies, credentials, evidence logs or unrelated files.
3. Run each asset pipeline's `bundle exec rake compatibility`. These install the actual
   built archive, not a path dependency. Record Ruby/Rails/pipeline versions, exact
   commands and the package SHA256. Keep the verified archive unchanged for handoff.
4. For reproducible packaging across days, build with an agreed `SOURCE_DATE_EPOCH`
   and record it. Use the same epoch for comparisons; do not confuse tarball hashes,
   source commit IDs and distributable gem hashes.

## Publication, only when authorized

Confirm the RubyGems name is available and the intended maintainers own it. Prefer
RubyGems trusted publishing with a protected release environment and explicit human
approval, as in the payment-icons precedent. Configure that integration separately;
never embed a RubyGems token in code or a workflow. Publish only an approved exact
revision after independent review and current CI. Verify the published package and
record its digest before switching Console to a released dependency.

Never overwrite an existing release. Corrections require a new version. A local
archive or public source repository does not prove RubyGems publication or deployment.
No additional trademark review is imposed by this guide; retain the license/NOTICE
and existing product authorization.
