.PHONY: install install-deps install-deps-macos install-deps-linux install-completions uninstall help test test-unit install-test-deps install-gui uninstall-gui

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
BASH_COMPLETION_DIR ?= $(PREFIX)/etc/bash_completion.d
ZSH_COMPLETION_DIR ?= $(PREFIX)/share/zsh/site-functions
SERVICES_DIR ?= $(HOME)/Library/Services

# Detect OS
UNAME_S := $(shell uname -s)

help:
	@echo "lazy CLI - Makefile targets"
	@echo ""
	@echo "  make install-deps       Install system dependencies"
	@echo "  make install            Install lazy CLI and shell completions"
	@echo "  make uninstall          Remove lazy CLI and completions"
	@echo "  make install-gui        Install the Finder Quick Actions (macOS)"
	@echo "  make uninstall-gui      Remove the Finder Quick Actions (macOS)"
	@echo "  make test               Run all tests"
	@echo "  make install-test-deps  Install test dependencies (bats-core)"
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

# Install the point-and-click Finder Quick Actions (macOS only). Installs both
# `lazy` and the `lazy-gui` dispatcher, then copies the three .workflow bundles
# into ~/Library/Services, rewriting the dispatcher path to match BINDIR.
install-gui:
ifneq ($(UNAME_S),Darwin)
	@echo "install-gui is macOS-only (it installs Finder Quick Actions)."
	@exit 1
endif
	@echo "Installing lazy and lazy-gui to $(BINDIR)..."
	@sudo mkdir -p $(BINDIR)
	@sudo install -m 755 lazy $(BINDIR)/lazy
	@sudo install -m 755 gui/lazy-gui $(BINDIR)/lazy-gui
	@echo "Installing Finder Quick Actions to $(SERVICES_DIR)..."
	@mkdir -p "$(SERVICES_DIR)"
	@for app in "Lazy Image" "Lazy PDF" "Lazy Video"; do \
		rm -rf "$(SERVICES_DIR)/$$app.workflow"; \
		cp -R "gui/quick-actions/$$app.workflow" "$(SERVICES_DIR)/"; \
		sed -i '' "s|/usr/local/bin/lazy-gui|$(BINDIR)/lazy-gui|g" "$(SERVICES_DIR)/$$app.workflow/Contents/document.wflow"; \
	done
	@/System/Library/CoreServices/pbs -flush 2>/dev/null || true
	@echo ""
	@echo "Installed! In Finder, right-click a file -> Quick Actions -> Lazy Image / Lazy PDF / Lazy Video."
	@echo "If they don't appear, enable them in System Settings > Extensions > Finder (or log out and back in)."

uninstall-gui:
	@echo "Removing lazy-gui from $(BINDIR)..."
	@sudo rm -f $(BINDIR)/lazy-gui
	@echo "Removing Finder Quick Actions from $(SERVICES_DIR)..."
	@rm -rf "$(SERVICES_DIR)/Lazy Image.workflow" "$(SERVICES_DIR)/Lazy PDF.workflow" "$(SERVICES_DIR)/Lazy Video.workflow"
	@/System/Library/CoreServices/pbs -flush 2>/dev/null || true
	@echo "Removed. (The lazy CLI itself is untouched; use 'make uninstall' to remove it.)"

install-test-deps:
	@echo "Installing test dependencies..."
ifeq ($(UNAME_S),Darwin)
	brew install bats-core
else ifeq ($(UNAME_S),Linux)
	@if command -v apt-get &> /dev/null; then \
		sudo apt-get update && sudo apt-get install -y bats; \
	elif command -v dnf &> /dev/null; then \
		sudo dnf install -y bats; \
	elif command -v pacman &> /dev/null; then \
		sudo pacman -S --noconfirm bash-bats; \
	else \
		echo "Installing bats-core from git..."; \
		git clone https://github.com/bats-core/bats-core.git /tmp/bats-core && \
		cd /tmp/bats-core && sudo ./install.sh /usr/local && \
		rm -rf /tmp/bats-core; \
	fi
endif
	@echo "bats-core installed."

test:
	@if ! command -v bats &> /dev/null; then \
		echo "Error: bats-core not installed. Run 'make install-test-deps' first."; \
		exit 1; \
	fi
	@echo "Running tests..."
	bats tests/

test-unit:
	@if ! command -v bats &> /dev/null; then \
		echo "Error: bats-core not installed. Run 'make install-test-deps' first."; \
		exit 1; \
	fi
	@echo "Running unit tests..."
	bats tests/*.bats
