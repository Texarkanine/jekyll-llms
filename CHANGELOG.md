# Changelog

All notable changes to this project will be documented in this file.

## 0.2.0

### Fixed

- Ensure that one invalid markdown file will not block publishing of all markdown files.

## 0.1.1

### Changed

- Exclude `/README.md` and `/CHANGELOG.md` by default. Set `llms.exclude` to replace this list.

### Fixed

- Copy Markdown sidecars only based off already existing  Markdown files
- Keep HTML-source entries linked to their original URLs in `llms.txt` and skip Markdown alternate links for them.

## 0.1.0 - 2026-05-03

### Added

- Generate `llms.txt` for included pages, posts, and output collections.
- Generate Markdown source sidecars for included entries.
- Add HTML alternate links pointing to generated Markdown sidecars.
