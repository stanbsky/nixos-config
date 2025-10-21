{ config, pkgs, lib, home-manager, ... }:

let
  user = "stanborzhemsky";
  # Define the content of your file as a derivation
  myEmacsLauncher = pkgs.writeScript "emacs-launcher.command" ''
    #!/bin/sh
    emacsclient -c -n &
  '';
  sharedFiles = import ../shared/files.nix { inherit config pkgs; };
  additionalFiles = import ./files.nix { inherit user config pkgs; };
in
{
  imports = [
   ./dock
  ];

  # It me
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    casks = pkgs.callPackage ./casks.nix {};
    brews = pkgs.callPackage ./brews.nix {};
    # onActivation.cleanup = "uninstall";

    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    # If you have previously added these apps to your Mac App Store profile (but not installed them on this system),
    # you may receive an error message "Redownload Unavailable with This Apple ID".
    # This message is safe to ignore. (https://github.com/dustinlyons/nixos-config/issues/83)
    masApps = {
      "tailscale" = 1475387142;
      # "wireguard" = 1451685025;
    };
  };

  # Enable home-manager
  home-manager = {
    useGlobalPkgs = true;
    users.${user} = { pkgs, config, lib, ... }:{
      home = {
        enableNixpkgsReleaseCheck = false;
        packages = pkgs.callPackage ./packages.nix {};
        file = lib.mkMerge [
          sharedFiles
          additionalFiles
          { "emacs-launcher.command".source = myEmacsLauncher; }
        ];
        stateVersion = "23.11";
        sessionVariables = {
          RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
        };
      };
      programs = {} // import ../shared/home-manager.nix { inherit config pkgs lib; };

      # Marked broken Oct 20, 2022 check later to remove this
      # https://github.com/nix-community/home-manager/issues/3344
      manual.manpages.enable = false;
    };
  };

  # Fully declarative dock using the latest from Nix Store
  local.dock = {
    enable = true;
    username = user;
    entries = [
      { path = "/System/Library/CoreServices/Finder.app/"; }
      { path = "/Applications/Google Chrome.app/"; }
      { path = "/Applications/Ghostty.app/"; }
      { path = "/Applications/Nix Apps/Zed.app/"; }
      { path = "/Applications/Claude.app/"; }
      { path = "/Users/stanborzhemsky/Applications/Notion.app/"; }
      { path = "/Applications/Linear.app/"; }
      { path = "/System/Applications/Notes.app/"; }
      { path = "/Applications/1Password.app/"; }
      # { path = "${pkgs.alacritty}/Applications/Alacritty.app/"; }
      { path = "/Users/stanborzhemsky/Applications/Slack.app/"; }
      { path = "/Applications/zoom.us.app/"; }
      { path = "/Applications/Microsoft Teams.app/"; }
      { path = "/Applications/Endel.app/"; }
      { path = "/System/Applications/System Settings.app/"; }
      { path = "/System/Applications/Utilities/Activity Monitor.app/"; }
      {
        path = toString myEmacsLauncher;
        section = "others";
      }
      {
        path = "${config.users.users.${user}.home}/Downloads";
        section = "others";
        options = "--sort name --view grid --display stack";
      }
    ];
  };

}
