# lazy

A CLI tool for common file operations using ghostscript, imagemagick, and rsync.

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

# Image operations
lazy image resize photo.jpg -w 800                # Resize to width 800px
lazy image resize photo.jpg -s 800x600            # Resize to exact dimensions
lazy image convert photo.png -o photo.webp        # Convert format
lazy image optimize photo.jpg -q 80               # Optimize file size
lazy image batch_convert *.png                    # Batch convert to JPG
lazy image batch_convert *.png -f webp -q 90      # Batch convert to WebP
lazy image batch_convert *.png -r 50              # Convert and resize to 50%

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

## Requirements

- macOS or Linux
- ghostscript (for PDF operations)
- imagemagick (for image operations)
- rsync (for backup operations)
