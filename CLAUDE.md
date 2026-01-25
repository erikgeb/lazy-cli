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
./lazy image resize test.jpg -w 800
./lazy image batch_convert *.png -f webp -g
./lazy video convert *.mov
./lazy backup home /mnt/external
```

## Architecture

- `lazy` - Single bash script containing all CLI logic
- `Makefile` - Handles dependency installation (detects OS and package manager) and CLI installation
- `completions/lazy.bash` - Bash completion script
- `completions/_lazy` - Zsh completion script

The CLI uses a command/subcommand pattern:
- `lazy pdf <subcommand>` - PDF operations via ghostscript (`gs`)
- `lazy image <subcommand>` - Image operations via imagemagick (`convert`)
- `lazy video <subcommand>` - Video operations via ffmpeg
- `lazy backup <subcommand>` - Backup operations via rsync

Image commands use the `img_convert` wrapper function which applies common parameters (`-strip -interlace Plane`) to all conversions. Both `convert` and `batch_convert` support `-g/--gray` for grayscale conversion.

Configuration is stored in `~/.config/lazy/config` (e.g., last used backup volume).

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
