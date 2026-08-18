# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/revelrylabs/text_chunker_ex/compare/v0.7.0...HEAD
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
