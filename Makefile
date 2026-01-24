.PHONY: install install-deps install-deps-macos install-deps-linux uninstall help

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

# Detect OS
UNAME_S := $(shell uname -s)

help:
	@echo "lazy CLI - Makefile targets"
	@echo ""
	@echo "  make install-deps    Install system dependencies (ghostscript, imagemagick)"
	@echo "  make install         Install lazy CLI to $(BINDIR)"
	@echo "  make uninstall       Remove lazy CLI from $(BINDIR)"
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
	brew install ghostscript imagemagick

install-deps-linux:
	@echo "Installing dependencies on Linux..."
	@if command -v apt-get &> /dev/null; then \
		sudo apt-get update && sudo apt-get install -y ghostscript imagemagick; \
	elif command -v dnf &> /dev/null; then \
		sudo dnf install -y ghostscript ImageMagick; \
	elif command -v yum &> /dev/null; then \
		sudo yum install -y ghostscript ImageMagick; \
	elif command -v pacman &> /dev/null; then \
		sudo pacman -S --noconfirm ghostscript imagemagick; \
	elif command -v zypper &> /dev/null; then \
		sudo zypper install -y ghostscript ImageMagick; \
	else \
		echo "Error: No supported package manager found (apt, dnf, yum, pacman, zypper)"; \
		exit 1; \
	fi

install: lazy
	@echo "Installing lazy to $(BINDIR)..."
	@mkdir -p $(BINDIR)
	@install -m 755 lazy $(BINDIR)/lazy
	@echo "Installed! Run 'lazy doctor' to check dependencies."

uninstall:
	@echo "Removing lazy from $(BINDIR)..."
	@rm -f $(BINDIR)/lazy
	@echo "Uninstalled."
