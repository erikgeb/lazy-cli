# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

lazy is a bash CLI tool that wraps ghostscript, imagemagick, ffmpeg, and rsync to provide simple commands for PDF, image, video, and backup operations on macOS and Linux.

## Commands

```bash
# Install dependencies
make install-deps

# Install CLI to /usr/local/bin
make install

# Run directly without installing
./lazy doctor
./lazy pdf compress test.pdf
./lazy image convert test.jpg -w 800
./lazy image convert *.png -f webp -g
./lazy video convert *.mov -c h264 -r 1080p
./lazy backup home /mnt/external
```

## Architecture

- `lazy` - Single bash script containing all CLI logic
- `Makefile` - Handles dependency installation (detects OS and package manager) and CLI installation
- `completions/lazy.bash` - Bash completion script
- `completions/_lazy` - Zsh completion script
- `gui/lazy-gui` - macOS Finder GUI dispatcher (osascript dialogs) that shells out to `lazy`
- `gui/quick-actions/*.workflow` - Finder Quick Action bundles; each just runs `lazy-gui <category> "$@"`

The CLI uses a command/subcommand pattern:
- `lazy pdf <subcommand>` - PDF operations via ghostscript (`gs`): `compress`, `merge`
- `lazy image convert` - Image operations via imagemagick: format, quality, grayscale, and resizing (percentage `-r` or exact pixels `-s`/`-w`/`-h`) in one command
- `lazy video convert` - Video operations via ffmpeg: H.265 (default) or H.264 (`-c`), quality mode (`-m`), and optional resolution cap (`-r`)
- `lazy backup <subcommand>` - Backup operations via rsync: `home`

Image conversions go through the `img_convert` wrapper, which applies common parameters (`-strip -interlace Plane`).

Every command writes output next to the input and never overwrites: `unique_path` returns a non-conflicting name using the macOS Finder convention (`foo.ext`, then `foo 2.ext`, ...). There is no overwrite prompt or skip-if-exists behavior.

Configuration is stored in `~/.config/lazy/config` (e.g., last used backup volume).

## macOS GUI (Finder Quick Actions)

`gui/lazy-gui` is the only place with GUI logic: it asks a few questions via `osascript`,
runs the matching `lazy` command, and relies on `lazy`'s **exit code** to decide success.
It does not reveal anything — the output lands next to the input, so Finder shows it
automatically. Success is silent; only failures pop a dialog. The one exception is video
(a long job), which shows a start and a completion notification. Because success/failure
rides on the exit code, `image convert` and `video convert` exit non-zero when they produce
nothing (e.g. every input was missing).

`gui/lazy-gui` is written for bash 3.2 (the interpreter Automator services use) — avoid
associative arrays, `mapfile`, and `set -u`. The three `.workflow` bundles are thin and
static; to expose a new operation in the GUI, edit `gui/lazy-gui`, not the bundles.
`make install-gui` / `uninstall-gui` manage installation. GUI flows are tested in
`tests/gui.bats` by sourcing the dispatcher and stubbing the `ui_*` helpers.

## Adding New Commands

1. Add a `cmd_<category>_<action>` function (e.g., `cmd_pdf_split`)
2. Add the subcommand case to the parent command function (e.g., `cmd_pdf`)
3. Update help text in both the subcommand and main help
4. **Update README.md** with usage examples for the new command
5. **Update completion scripts** in `completions/` (both `lazy.bash` and `_lazy`)

## Testing

Tests use [bats-core](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

```bash
# Install test dependencies
make install-test-deps

# Run all tests
make test

# Run tests for a specific module
bats tests/image.bats
```

Test files:
- `tests/test_helper.bash` - Common setup, teardown, and helper functions
- `tests/lazy.bats` - Main CLI tests (help, version, doctor)
- `tests/pdf.bats` - PDF command tests
- `tests/image.bats` - Image command tests
- `tests/video.bats` - Video command tests
- `tests/backup.bats` - Backup command tests

## Dependencies

- ghostscript: provides `gs` command for PDF manipulation
- imagemagick: provides `convert` command for image manipulation
- ffmpeg: provides video conversion and encoding
- rsync: provides backup functionality with incremental sync
