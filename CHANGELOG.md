# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `usage-rules.md` - rules for AI coding agents via [usage_rules](https://hex.pm/packages/usage_rules)

### Changed

- Corrected the `TextChunker` moduledoc: `:chunk_size` and `:chunk_overlap` are measured in
  graphemes by default

## [1.0.0] - 2026-10-16

First stable release. The public API is `TextChunker.split/2`, `TextChunker.supported_formats/0`,
`%TextChunker.Chunk{}`, `TextChunker.Error`, and the `TextChunker.Strategy` callback.

### Changed

- **Breaking:** `TextChunker.split/2` raises `TextChunker.Error` on invalid options instead of
  returning `{:error, String.t()}`; the return type is now always `[TextChunker.Chunk.t()]`.
  This only affects you if you pattern-match on `{:error, message}` from `TextChunker.split/2`
  ([#102](https://github.com/revelrylabs/text_chunker_ex/pull/102))
- **Breaking:** empty input returns `[]` instead of a single sentinel chunk. This only affects
  you if you were doing anything special with the `"No chunks created"` chunk text; if you
  weren't, this stops that made-up chunk from polluting your data
  ([#102](https://github.com/revelrylabs/text_chunker_ex/pull/102))
- **Breaking:** `TextChunker.ChunkerBehaviour` is renamed to `TextChunker.Strategy`. This
  shouldn't really affect anyone, since you couldn't plug in your own strategies before anyway
- `TextChunker.Strategies.RecursiveChunk.Separators` is hidden from the docs; it is an
  implementation detail of the built-in strategy, not public API
- Chunk assembly is linear in the number of chunks: chunk and split lists are accumulated as
  deep lists instead of appended with `++`
  ([#99](https://github.com/revelrylabs/text_chunker_ex/pull/99))
- Credo runs in CI ([#104](https://github.com/revelrylabs/text_chunker_ex/pull/104)); text files
  check out with LF line endings on every platform
  ([#105](https://github.com/revelrylabs/text_chunker_ex/pull/105))

### Added

- `:strategy` accepts any module declaring `@behaviour TextChunker.Strategy` and
  implementing `split/2`, not only the built-in `RecursiveChunk`
  ([#102](https://github.com/revelrylabs/text_chunker_ex/pull/102))
- `TextChunker.supported_formats/0` returns the accepted `:format` values
  ([#102](https://github.com/revelrylabs/text_chunker_ex/pull/102))

## [0.7.0] - 2026-07-31

### Changed

- **Breaking:** a `:chunk_overlap` greater than `:chunk_size` is now rejected
  with a validation error ([#98](https://github.com/revelrylabs/text_chunker_ex/pull/98))
- Large performance improvement: the merge loop tracks split sizes
  incrementally instead of re-measuring accumulated text on every step
  ([#95](https://github.com/revelrylabs/text_chunker_ex/pull/95))

### Added

- Property-based invariant tests and coverage for previously untested
  separator sets ([#92](https://github.com/revelrylabs/text_chunker_ex/pull/92))
- AI contribution policy ([#84](https://github.com/revelrylabs/text_chunker_ex/pull/84))

### Fixed

- Typespec and README inaccuracies; modernized CI
  ([#83](https://github.com/revelrylabs/text_chunker_ex/pull/83))

## [0.6.1] - 2026-04-07

### Added

- `:vtt` (WebVTT subtitle) format support ([#79](https://github.com/revelrylabs/text_chunker_ex/pull/79))

## [0.6.0] - 2026-01-14

### Fixed

- The `:get_chunk_size` function is now used when merging splits, so custom
  sizing (e.g. token counting) applies to chunk assembly, not just splitting
  ([#74](https://github.com/revelrylabs/text_chunker_ex/pull/74))

## [0.5.2] - 2025-09-08

### Fixed

- Infinite recursion on large homogeneous text with nothing left to split
  ([#63](https://github.com/revelrylabs/text_chunker_ex/pull/63))

## [0.5.1] - 2025-08-29

### Fixed

- Added the `""` fallback separator to every separator set so oversized text
  can always be split ([#61](https://github.com/revelrylabs/text_chunker_ex/pull/61))

## [0.5.0] - 2025-08-27

### Fixed

- Byte position tracking in chunk metadata; improved splitting performance
  ([#56](https://github.com/revelrylabs/text_chunker_ex/pull/56))

## [0.4.0] - 2025-07-11

### Added

- `:get_chunk_size` option for custom chunk-size measurement, e.g. token
  counting ([#47](https://github.com/revelrylabs/text_chunker_ex/pull/47))

### Changed

- CI runs tests on pull requests ([#49](https://github.com/revelrylabs/text_chunker_ex/pull/49))

## [0.3.2] - 2025-01-23

### Changed

- Maintenance release: dependency updates and release-process documentation
  ([#36](https://github.com/revelrylabs/text_chunker_ex/pull/36))

## [0.3.1] - 2024-05-17

### Added

- `:html` format support ([#23](https://github.com/revelrylabs/text_chunker_ex/pull/23))

## [0.3.0] - 2024-04-18

### Added

- Option validation via NimbleOptions; invalid options return an error tuple
  ([#19](https://github.com/revelrylabs/text_chunker_ex/pull/19))

## [0.2.0] - 2024-03-12

### Changed

- **Breaking:** `TextChunker.Chunker.split/2` renamed to `TextChunker.split/2`
  ([#8](https://github.com/revelrylabs/text_chunker_ex/pull/8))
- **Breaking:** the `:strategy` option takes a module instead of a function
  capture ([#12](https://github.com/revelrylabs/text_chunker_ex/pull/12))

## [0.1.2] - 2024-03-08

### Added

- `:python` format support ([#9](https://github.com/revelrylabs/text_chunker_ex/pull/9))

## [0.1.1] - 2024-02-28

### Added

- SECURITY.md ([#2](https://github.com/revelrylabs/text_chunker_ex/pull/2))

## [0.1.0] - 2024-02-27

### Added

- Initial release: recursive, separator-based semantic chunking with
  configurable chunk size, overlap, and format, and byte-range metadata on
  every chunk

[Unreleased]: https://github.com/revelrylabs/text_chunker_ex/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/revelrylabs/text_chunker_ex/compare/v0.7.0...v1.0.0
[0.7.0]: https://github.com/revelrylabs/text_chunker_ex/compare/v0.6.1...v0.7.0
[0.6.1]: https://github.com/revelrylabs/text_chunker_ex/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/revelrylabs/text_chunker_ex/compare/0.5.2...v0.6.0
[0.5.2]: https://github.com/revelrylabs/text_chunker_ex/compare/v0.5.1...0.5.2
[0.5.1]: https://github.com/revelrylabs/text_chunker_ex/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/revelrylabs/text_chunker_ex/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/revelrylabs/text_chunker_ex/compare/v0.3.2...v0.4.0
[0.3.2]: https://github.com/revelrylabs/text_chunker_ex/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/revelrylabs/text_chunker_ex/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/revelrylabs/text_chunker_ex/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/revelrylabs/text_chunker_ex/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/revelrylabs/text_chunker_ex/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/revelrylabs/text_chunker_ex/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/revelrylabs/text_chunker_ex/releases/tag/v0.1.0
