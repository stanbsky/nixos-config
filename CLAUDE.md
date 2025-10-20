# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Nix flake-based configuration for both NixOS (Linux) and nix-darwin (macOS). It uses home-manager for user environment management and supports multiple system architectures (x86_64 and aarch64).

**User:** stanborzhemsky
**Primary systems:** macOS (aarch64-darwin, x86_64-darwin), NixOS (x86_64-linux, aarch64-linux)

## Build and Deployment Commands

### macOS (Darwin)

```bash
# Build without switching (dry run)
nix run .#build

# Build and switch to new generation
nix run .#build-switch

# Apply initial configuration (token replacement for user info)
nix run .#apply

# Rollback to previous generation
nix run .#rollback

# Clean up old generations
nix run .#clean
```

### NixOS (Linux)

```bash
# Build and switch to new generation
nix run .#build-switch

# Apply initial configuration (includes disk setup prompts)
nix run .#apply

# Clean up old generations
nix run .#clean
```

**Note:** The `apply` script is designed for initial setup and replaces placeholder tokens (%USER%, %EMAIL%, %NAME%, %HOST%, %INTERFACE%, %DISK%) with actual values. It should not be used for routine updates.

## Architecture

### Flake Structure

The flake (`flake.nix`) defines:
- **Inputs:** nixpkgs, home-manager, nix-darwin, nix-homebrew, homebrew taps, disko
- **Outputs:** Platform-specific configurations generated with `genAttrs` for each system type
- **Apps:** Shell scripts in `apps/{system}/` for build, apply, rollback, etc.

### Directory Layout

```
├── flake.nix              # Main flake entry point
├── apps/                  # Platform-specific build/deployment scripts
│   ├── aarch64-darwin/
│   ├── x86_64-darwin/
│   └── x86_64-linux/
├── hosts/
│   ├── darwin/            # macOS host configuration
│   └── nixos/             # NixOS host configuration
├── modules/
│   ├── shared/            # Shared configuration (git, zsh, vim, tmux, alacritty)
│   ├── darwin/            # macOS-specific (homebrew, dock, system defaults)
│   └── nixos/             # Linux-specific (X11, bspwm, picom, services)
└── overlays/              # Nix package overlays (auto-imported)
```

### Module Organization

**modules/shared/**: Contains platform-agnostic configuration imported by both Darwin and NixOS:
- `home-manager.nix`: User programs (zsh, git, vim, tmux, alacritty, ssh)
- `packages.nix`: Shared package list
- `files.nix`: Static config files (immutable)
- `default.nix`: Overlay imports and nixpkgs config

**modules/darwin/**: macOS-specific configuration:
- `home-manager.nix`: User setup, homebrew packages/casks, dock configuration
- `packages.nix`: macOS-specific packages
- `casks.nix`: Homebrew casks
- `brews.nix`: Homebrew formulae
- `dock/`: Declarative dock management module
- `files.nix`: macOS-specific static files

**modules/nixos/**: Linux-specific configuration:
- `default.nix`: System-level config (boot, networking, services, X11, bspwm)
- `disk-config.nix`: Disko-based disk partitioning
- `home-manager.nix`: User programs
- `packages.nix`: NixOS-specific packages
- `files.nix`: Linux-specific static files

**overlays/**: Files here run automatically during builds. Common uses: patches, version locking, temporary workarounds.

### Key Integration Points

1. **Home Manager Integration:**
   - Darwin: Configured in `modules/darwin/home-manager.nix` via `home-manager.darwinModules.home-manager`
   - NixOS: Configured via `home-manager.nixosModules.home-manager` in flake.nix

2. **Homebrew Integration (macOS only):**
   - Uses `nix-homebrew` to manage Homebrew declaratively
   - Taps are pinned via flake inputs (homebrew-core, homebrew-cask, homebrew-bundle)
   - `mutableTaps = false` ensures reproducibility

3. **Emacs Setup:**
   - Uses custom emacs-overlay from https://github.com/dustinlyons/emacs-overlay
   - Darwin: Runs as launchd daemon
   - NixOS: Configured as systemd service (commented out by default)

4. **SSH Configuration:**
   - Managed by home-manager for Linux only (`modules/shared/home-manager.nix:261`)
   - macOS uses default SSH config to support keychain integration

## Configuration Patterns

### Adding Packages

- **Shared packages:** Add to `modules/shared/packages.nix`
- **Platform-specific packages:** Add to `modules/darwin/packages.nix` or `modules/nixos/packages.nix`
- **Homebrew (macOS):** Add to `modules/darwin/casks.nix` or `modules/darwin/brews.nix`

### Modifying System Defaults (macOS)

Edit `hosts/darwin/default.nix` under `system.defaults` section. Current customizations include dock position, key repeat, trackpad settings.

### Window Manager Configuration (NixOS)

The system uses bspwm as the window manager with:
- **Display Manager:** LightDM with slick greeter
- **Compositor:** Picom with animations, rounded corners, shadows
- **Hotkeys:** Configured via sxhkd (see `modules/nixos/README.md` for essential hotkeys)

### Adding Overlays

Create a `.nix` file in the `overlays/` directory. It will be automatically imported during builds via `modules/shared/default.nix`.

### Multiple Host Support

By default, the flake generates one configuration per platform. To add named hosts with different configurations:

1. Create `hosts/nixos/hostname/default.nix` or `hosts/darwin/hostname/default.nix`
2. Add named configuration to flake.nix `nixosConfigurations` or `darwinConfigurations`
3. Build with: `nix run .#build-switch -- --host hostname`

## Important Files

- **flake.nix:32-73**: Defines flake apps and system configurations
- **hosts/darwin/default.nix**: macOS system settings (Nix config, emacs daemon, system defaults)
- **hosts/nixos/default.nix**: NixOS system config (boot, services, X11, users)
- **modules/shared/home-manager.nix**: Primary shared user configuration (shell, git, vim, tmux)
- **modules/darwin/home-manager.nix:71-101**: Declarative dock configuration

## Development Workflow

1. Make changes to relevant module files
2. Test with `nix run .#build` (Darwin) to verify build succeeds
3. Apply with `nix run .#build-switch` to activate changes
4. Use `nix run .#rollback` (Darwin) to revert if needed

## Notes

- **Experimental features:** Flakes and nix-command are enabled via `extraOptions`
- **Garbage collection:** Darwin runs automatic GC weekly (Sunday 2am), keeping 30 days
- **NixOS hostname placeholder:** `hosts/nixos/default.nix:37` uses `%HOST%` token, replaced by apply script
- **State versions:** Darwin stateVersion=5, NixOS stateVersion="21.05" (don't change)
- **Emacs timeout:** NixOS systemd service has 7min timeout for cache-less builds
