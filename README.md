# lazy

A CLI tool for common file operations using ghostscript, imagemagick, ffmpeg, and rsync.

[![Tests](https://github.com/erikgeb/lazy-cli/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/erikgeb/lazy-cli/actions/workflows/test.yml)

## Installation

```bash
# Install system dependencies (ghostscript, imagemagick, rsync)
make install-deps

# Install the lazy CLI (requires sudo for system directories)
make install
```

## Usage

```bash
# Check dependencies
lazy doctor

# PDF operations
lazy pdf compress document.pdf                    # Compress with default quality
lazy pdf compress document.pdf -q printer         # High quality compression
lazy pdf merge file1.pdf file2.pdf -o merged.pdf  # Merge PDFs

# Image operations (one `convert` command for format, quality, and resizing)
lazy image convert *.png                          # Convert to JPG (default, quality 85)
lazy image convert *.png -f webp -q 90            # Convert to WebP at quality 90
lazy image convert photo.png -o photo.webp        # Single file to an explicit output
lazy image convert *.png -g                       # Convert to grayscale
lazy image convert *.jpg -r 50                    # Resize to 50% of original
lazy image convert photo.jpg -w 800               # Resize to width 800px (keep aspect)
lazy image convert photo.jpg -s 800x600           # Resize to exact dimensions

# Video operations (one `convert` command; H.265 by default)
lazy video convert video.mov                      # Convert to MP4/H.265, keep resolution + audio
lazy video convert *.mov -m small                 # Aggressive compression (re-encodes audio)
lazy video convert *.mov -m quality               # Higher quality, longer encoding
lazy video convert *.mov -c h264                  # Use H.264 for wider compatibility
lazy video convert *.mov -r 1080p                 # Cap resolution at 1080p (scales down only)

# Backup operations
lazy backup home /mnt/external                    # Backup home to external volume
lazy backup home /mnt/external -n                 # Dry run (show what would transfer)
lazy backup home                                  # Use last volume (if previously set)
```

## PDF Quality Options

- `screen` - lowest quality, smallest size (72 dpi)
- `ebook` - medium quality (150 dpi) [default]
- `printer` - high quality (300 dpi)
- `prepress` - highest quality, preserves color (300 dpi)

## Image `convert` Options

- `-f, --format EXT` - output format (default: `jpg`)
- `-q, --quality N` - quality 1-100 for jpg/webp (default: `85`)
- `-g, --gray` - convert to grayscale
- `-o, --output FILE` - explicit output path (single input only; extension sets the format)
- Resize (choose at most one; `-r` cannot be combined with `-s`/`-w`/`-h`):
  - `-r, --resize N` - scale to N% of the original
  - `-s, --size WxH` - resize to exact dimensions (ignores aspect ratio)
  - `-w, --width N` / `-h, --height N` - resize by one side, keeping aspect ratio

## Video `convert` Options

- `-m, --mode` - `balanced` (default), `small` (smaller), or `quality` (higher quality)
- `-c, --codec` - `h265` (HEVC, smaller; default) or `h264` (more compatible)
- `-r, --resolution` - `input` (keep original; default), `4k`, `1080p`, or `720p`
  (scales down only, never up; aspect ratio preserved for landscape and portrait)

## Output Files

Commands write output next to the input and **never overwrite**. If the target name
already exists, a numbered suffix is added following the macOS Finder convention
(`photo_q85.jpg`, then `photo_q85 2.jpg`, `photo_q85 3.jpg`, ...). No overwrite prompt.

## GUI for Finder (macOS)

For people who'd rather not use the terminal, lazy ships three **Finder Quick Actions** —
`Lazy Image`, `Lazy PDF`, and `Lazy Video`. Install them with:

```bash
make install-gui      # installs lazy + lazy-gui and the Quick Actions
make uninstall-gui    # removes them again
```

Then, in Finder, right-click a file (or several) and choose **Quick Actions → Lazy Image /
Lazy PDF / Lazy Video**. A couple of simple dialogs ask for the format/quality/size (or
compression settings for video), and the new file appears right next to the original — no
confirmation pop-up on success (video shows a start/finish notification since it takes a
while). If something goes wrong, a dialog explains what. Each action only appears for the
matching file type. If they don't show up at first, enable them under **System Settings →
Extensions → Finder**, or log out and back in.

Under the hood the Quick Actions just call `gui/lazy-gui`, a small dispatcher that runs the
same `lazy` commands documented above — so there's no separate conversion logic to maintain.
Adding a new option to the GUI means editing `gui/lazy-gui`, not the workflow bundles.

> If a Quick Action ever fails to load after a macOS update, open the matching
> `gui/quick-actions/*.workflow` in Automator once and re-save it; the shell action inside
> is a single line (`lazy-gui <category> "$@"`).

## Shell Completions

Shell completions are installed automatically with `make install`. To activate:

**Bash:** Add to `~/.bashrc`:
```bash
source /usr/local/etc/bash_completion.d/lazy
```

**Zsh:** Completions should work automatically. If not, add to `~/.zshrc`:
```zsh
fpath=(/usr/local/share/zsh/site-functions $fpath)
autoload -Uz compinit && compinit
```

## Testing

```bash
# Install test dependencies (bats-core)
make install-test-deps

# Run all tests
make test
```

## Requirements

- macOS or Linux
- ghostscript (for PDF operations)
- imagemagick (for image operations)
- ffmpeg (for video operations)
- rsync (for backup operations)
