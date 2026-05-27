# nixos-config

Declarative macOS (and NixOS) configuration managed with [nix-darwin](https://github.com/LnL7/nix-darwin) and [home-manager](https://github.com/nix-community/home-manager).

---

## Nix basics you need to know

### The Nix store

Everything Nix builds lives in `/nix/store/`. Packages are never installed
"globally" the way Homebrew installs things into `/usr/local`. Instead, Nix
builds an immutable, content-addressed derivation in the store and symlinks it
into your active profile. Two packages can depend on different versions of the
same library without conflict because they each reference their own store path.

### Generations

Every time you run `just switch`, Nix creates a new *generation* — a snapshot of
your entire system configuration. The previous generation is kept intact. This is
what makes rollbacks instant: you just switch the active symlink back to an older
generation. Generations accumulate on disk until you garbage-collect them with
`just clean`.

### Flakes

A *flake* is a project with a `flake.nix` at the root that declares its
dependencies (*inputs*) and outputs (system configs, packages, apps, etc.) in a
reproducible way. `flake.lock` pins every input to an exact git commit, so two
people building from the same lock file get identical results.

**Key point:** `flake.lock` only tracks *Nix* inputs (nixpkgs, home-manager,
etc.). Homebrew packages are managed by Homebrew itself and never appear in
`flake.lock`.

### Flake inputs vs. package versions

- `nix flake update` bumps your flake inputs (e.g. pulls the latest nixpkgs
  commit). This is how you get newer versions of Nix-managed packages like
  ripgrep, kubectl, etc.
- It does **not** upgrade Homebrew casks. For those, run `just brew-upgrade`.

---

## Repository structure

```
.
├── flake.nix               # Entry point: declares all inputs and outputs
├── flake.lock              # Pins every input to an exact commit (commit this)
├── Justfile                # Common commands — run `just` to list them
│
├── apps/                   # Shell scripts exposed as `nix run .#<name>`
│   ├── aarch64-darwin/     # build, build-switch, clean, rollback, apply
│   └── x86_64-darwin/
│
├── hosts/
│   ├── darwin/             # macOS system-level config (Nix settings, emacs daemon,
│   │   └── default.nix     # system.defaults for dock/keyboard/trackpad)
│   └── nixos/              # NixOS system config (boot, networking, X11, services)
│       └── default.nix
│
├── modules/
│   ├── shared/             # Platform-agnostic config (imported by both Darwin & NixOS)
│   │   ├── packages.nix    # ← ADD SHARED PACKAGES HERE
│   │   ├── home-manager.nix # Shell (zsh), git, vim, tmux, alacritty, ssh
│   │   ├── files.nix       # Static config files managed by home-manager
│   │   └── default.nix     # Overlay imports and nixpkgs settings
│   │
│   ├── darwin/             # macOS-only config
│   │   ├── packages.nix    # ← ADD macOS-ONLY NIX PACKAGES HERE
│   │   ├── casks.nix       # ← ADD HOMEBREW CASKS (GUI apps) HERE
│   │   ├── brews.nix       # ← ADD HOMEBREW FORMULAE (CLI tools) HERE
│   │   ├── home-manager.nix # User setup, dock configuration
│   │   ├── files.nix       # macOS-specific static config files
│   │   └── dock/           # Declarative dock management module
│   │
│   └── nixos/              # NixOS-only config
│       ├── packages.nix    # NixOS-specific packages
│       ├── home-manager.nix # User programs
│       └── disk-config.nix # Disko-based disk partitioning
│
└── overlays/               # Nix overlays (auto-imported on build)
    └── 10-feather-font.nix # Example: patching or version-locking a package
```

---

## Day-to-day workflows

### Install a new package

**Nix package** (CLI tool, library, language runtime):
1. Find the package name: `just search <keyword>` or browse [search.nixos.org](https://search.nixos.org/packages)
2. Add it to `modules/shared/packages.nix` (available everywhere) or
   `modules/darwin/packages.nix` (macOS only)
3. `just switch`

**Homebrew cask** (GUI app like Docker Desktop, Ghostty, etc.):
1. Find the cask name at [formulae.brew.sh/cask](https://formulae.brew.sh/cask/)
2. Add it to `modules/darwin/casks.nix`
3. `just switch`

**Homebrew formula** (CLI tool you want Homebrew to manage instead of Nix):
1. Find the formula name at [formulae.brew.sh/formula](https://formulae.brew.sh/formula/)
2. Add it to `modules/darwin/brews.nix`
3. `just switch`

### Remove a package

Delete the line from the relevant file, then `just switch`. Nix will remove the
package from your profile. Old build outputs remain in `/nix/store` until you
run `just clean`.

### Upgrade packages

```bash
just update          # Bump all flake inputs (nixpkgs etc.) and rebuild
just brew-upgrade    # Upgrade Homebrew casks and formulae
```

### Test a change before committing

```bash
just build           # Compile the config without activating it — catches errors early
just switch          # Activate when you're happy
```

### Undo a bad switch

```bash
just rollback        # Interactive: pick a previous generation to revert to
```

---

## How the pieces fit together

```
flake.nix
  └── darwinConfigurations.<system>
        ├── nix-homebrew module      → manages Homebrew installation & taps
        ├── home-manager module      → manages user-level programs & dotfiles
        └── ./hosts/darwin           → imports modules/darwin/* and modules/shared/*
              ├── system.defaults    → keyboard repeat, trackpad, dock position
              ├── homebrew.casks     → from modules/darwin/casks.nix
              ├── homebrew.brews     → from modules/darwin/brews.nix
              └── home.packages      → from modules/darwin/packages.nix
                                       + modules/shared/packages.nix
```

### Why are there two package managers?

Nix and Homebrew serve different roles here:

| | Nix packages | Homebrew |
|---|---|---|
| **What** | CLI tools, libraries, runtimes, fonts | GUI apps (casks) + some CLI tools |
| **How managed** | `packages.nix` files | `casks.nix` / `brews.nix` |
| **Versions** | Pinned in `flake.lock`, updated with `nix flake update` | Homebrew manages its own versioning |
| **Appears in flake.lock?** | Yes (via nixpkgs input) | No |

In an ideal world everything would be in Nix, but many macOS GUI apps are only
packaged as Homebrew casks, so nix-homebrew bridges the gap by letting Homebrew
be configured declaratively from within the Nix config.

### Overlays

Files in `overlays/` are automatically imported during every build. Use them to:
- Override a package version (e.g. pin an older revision)
- Patch a package (e.g. apply an upstream fix that hasn't landed in nixpkgs yet)
- Add a package that doesn't exist in nixpkgs

---

## Useful commands

```bash
just                        # List all available recipes
just switch                 # The main command: rebuild and activate
just update                 # Bump all inputs and rebuild
just search <keyword>       # Search nixpkgs for a package
just try <package>          # Open a temp shell with a package, no install
just generations            # Show all past system generations
just rollback               # Revert to a previous generation
just clean                  # Delete old generations and garbage-collect
just inputs                 # Show flake inputs and their locked revisions
```
