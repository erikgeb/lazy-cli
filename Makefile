.PHONY: install install-deps install-deps-macos install-deps-linux install-completions uninstall help

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
BASH_COMPLETION_DIR ?= $(PREFIX)/etc/bash_completion.d
ZSH_COMPLETION_DIR ?= $(PREFIX)/share/zsh/site-functions

# Detect OS
UNAME_S := $(shell uname -s)

help:
	@echo "lazy CLI - Makefile targets"
	@echo ""
	@echo "  make install-deps    Install system dependencies (ghostscript, imagemagick)"
	@echo "  make install         Install lazy CLI and shell completions"
	@echo "  make uninstall       Remove lazy CLI and completions"
	@echo ""

install-deps:
ifeq ($(UNAME_S),Darwin)
	@$(MAKE) install-deps-macos
else ifeq ($(UNAME_S),Linux)
	@$(MAKE) install-deps-linux
else
	@echo "Unsupported OS: $(UNAME_S)"
	@exit 1
endif

install-deps-macos:
	@echo "Installing dependencies on macOS..."
	@if ! command -v brew &> /dev/null; then \
		echo "Error: Homebrew is required. Install from https://brew.sh"; \
		exit 1; \
	fi
	brew install ghostscript imagemagick rsync ffmpeg

install-deps-linux:
	@echo "Installing dependencies on Linux..."
	@if command -v apt-get &> /dev/null; then \
		sudo apt-get update && sudo apt-get install -y ghostscript imagemagick rsync ffmpeg; \
	elif command -v dnf &> /dev/null; then \
		sudo dnf install -y ghostscript ImageMagick rsync ffmpeg; \
	elif command -v yum &> /dev/null; then \
		sudo yum install -y ghostscript ImageMagick rsync ffmpeg; \
	elif command -v pacman &> /dev/null; then \
		sudo pacman -S --noconfirm ghostscript imagemagick rsync ffmpeg; \
	elif command -v zypper &> /dev/null; then \
		sudo zypper install -y ghostscript ImageMagick rsync ffmpeg; \
	else \
		echo "Error: No supported package manager found (apt, dnf, yum, pacman, zypper)"; \
		exit 1; \
	fi

install: lazy
	@if [ -f "$(BINDIR)/lazy" ]; then \
		echo "Warning: $(BINDIR)/lazy already exists."; \
		read -p "Overwrite? [y/N] " response; \
		case "$$response" in \
			[yY][eE][sS]|[yY]) ;; \
			*) echo "Installation aborted."; exit 1 ;; \
		esac; \
	fi
	@$(MAKE) install-completions
	@echo "Installing lazy to $(BINDIR)..."
	@sudo mkdir -p $(BINDIR)
	@sudo install -m 755 lazy $(BINDIR)/lazy
	@echo ""
	@echo "Installed! Run 'lazy doctor' to check dependencies."
	@echo ""
	@echo "Shell completions installed. To activate:"
	@echo "  Bash: Add 'source $(BASH_COMPLETION_DIR)/lazy' to ~/.bashrc"
	@echo "  Zsh:  Completions should work automatically. If not, add to ~/.zshrc:"
	@echo "        fpath=($(ZSH_COMPLETION_DIR) \$$fpath)"
	@echo "        autoload -Uz compinit && compinit"

install-completions:
	@echo "Installing shell completions..."
	@sudo mkdir -p $(BASH_COMPLETION_DIR)
	@sudo mkdir -p $(ZSH_COMPLETION_DIR)
	@sudo install -m 644 completions/lazy.bash $(BASH_COMPLETION_DIR)/lazy
	@sudo install -m 644 completions/_lazy $(ZSH_COMPLETION_DIR)/_lazy
	@echo "Completions installed to:"
	@echo "  Bash: $(BASH_COMPLETION_DIR)/lazy"
	@echo "  Zsh:  $(ZSH_COMPLETION_DIR)/_lazy"

uninstall:
	@echo "Removing lazy from $(BINDIR)..."
	@sudo rm -f $(BINDIR)/lazy
	@echo "Removing shell completions..."
	@sudo rm -f $(BASH_COMPLETION_DIR)/lazy
	@sudo rm -f $(ZSH_COMPLETION_DIR)/_lazy
	@echo "Uninstalled."
