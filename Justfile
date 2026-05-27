# Justfile for managing this nix-darwin configuration.
# Run `just` to list all available recipes.
#
# Prerequisites: `just` must be installed (it's in shared/packages.nix so it's
# always available after the first build).

# Show available recipes
default:
    @just --list

# ── Build & Switch ─────────────────────────────────────────────────────────────

# Dry-run build: compiles the config but doesn't activate it.
# Use this to catch errors before committing to a switch.
build:
    nix run .#build

# Build and activate: the main command you'll use after editing any .nix file.
# This rebuilds the entire system config, runs darwin-rebuild switch, and
# installs/removes Homebrew packages to match your declared lists.
switch:
    nix run .#build-switch

# ── Updating packages ──────────────────────────────────────────────────────────

# Update all flake inputs to their latest commits and rebuild.
#
# What this does:
#   - Bumps nixpkgs, home-manager, nix-darwin, and all other flake inputs in
#     flake.lock to their latest commits on the tracked branches.
#   - Does NOT touch Homebrew casks/formulae — Homebrew manages its own versions.
#
# Run this when you want newer Nix packages (e.g. a newer version of ripgrep,
# kubectl, etc.). After updating, always rebuild with `just switch`.
update:
    nix flake update
    nix run .#build-switch

# Update a single flake input without bumping everything else.
# Example: just update-input nixpkgs
update-input input:
    nix flake update {{input}}
    nix run .#build-switch

# Upgrade Homebrew itself and all installed casks/formulae to their latest
# versions, outside of Nix. Run this when you want newer GUI apps (e.g. a newer
# Ghostty, Docker Desktop, etc.) without waiting for a full flake update.
brew-upgrade:
    brew update && brew upgrade && brew upgrade --cask

# ── Adding & removing packages ─────────────────────────────────────────────────

# Open the shared Nix package list (tools available on both macOS and NixOS).
# Add a package name here, then run `just switch` to install it.
edit-packages:
    $EDITOR modules/shared/packages.nix

# Open the macOS-only Nix package list.
edit-darwin-packages:
    $EDITOR modules/darwin/packages.nix

# Open the Homebrew cask list (GUI apps installed via Homebrew).
# Add or remove a cask name here, then run `just switch` to apply.
# Find cask names at: https://formulae.brew.sh/cask/
edit-casks:
    $EDITOR modules/darwin/casks.nix

# Open the Homebrew formula list (CLI tools installed via Homebrew).
# Add or remove a formula name here, then run `just switch` to apply.
# Find formula names at: https://formulae.brew.sh/formula/
edit-brews:
    $EDITOR modules/darwin/brews.nix

# ── Rollback & garbage collection ──────────────────────────────────────────────

# Interactively roll back to a previous system generation.
# Nix keeps every generation you've ever built, so you can always undo a switch.
rollback:
    nix run .#rollback

# List all system generations (history of every `just switch` you've done).
generations:
    /run/current-system/sw/bin/darwin-rebuild --list-generations

# Delete generations older than 7 days and run the Nix garbage collector.
#
# Nix never deletes build outputs on its own — old package versions accumulate
# on disk until you explicitly GC them. Run this periodically to reclaim space.
# The current (active) generation is always kept regardless of age.
clean:
    nix run .#clean

# Aggressively clean: delete ALL old generations, then garbage-collect.
# Use when disk space is low. You lose the ability to roll back afterwards.
clean-all:
    sudo nix-collect-garbage -d
    nix store optimise

# ── Inspection & troubleshooting ───────────────────────────────────────────────

# Show what packages are currently installed in your Nix profile.
list-packages:
    nix profile list

# Search nixpkgs for a package by name/keyword.
# Example: just search ripgrep
search query:
    nix search nixpkgs {{query}}

# Show all flake inputs and their locked revisions.
# Useful for auditing exactly which version of nixpkgs you're on.
inputs:
    nix flake metadata

# Check the flake for evaluation errors without building anything.
check:
    nix flake check

# Open a temporary shell with a package available, without installing it.
# Great for one-off usage or testing before adding to packages.nix.
# Example: just try htop
try package:
    nix shell nixpkgs#{{package}}

# Show the current system generation and nix-darwin version.
info:
    darwin-rebuild --version
    /run/current-system/sw/bin/sw_vers
