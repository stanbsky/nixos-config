{ pkgs }:

with pkgs; [
  # General packages for development and system management
  alacritty
  bash-completion
  fish
  bat
  btop
  coreutils
  killall
  # openssh  # Use system SSH on macOS for UseKeychain support
  sqlite
  wget
  zip
  teams
  difftastic

  # Encryption and security tools
  age
  gnupg
  tailscale

  # Cloud-related tools and SDKs
  docker
  docker-compose
  awscli2
  eksctl
  azure-cli
  packer
  terraform

  # Media-related packages
  emacs-all-the-icons-fonts
  dejavu_fonts
  fd
  font-awesome
  hack-font
  noto-fonts
  noto-fonts-emoji
  meslo-lgs-nf

  # Text and terminal utilities
  (neovim.override {
    withPython3 = true;
    withNodeJs = true;
    withRuby = true;
    extraPython3Packages = ps: with ps; [ pynvim ];
  })
  zed-editor
  htop
  jetbrains-mono
  jq
  yq
  ripgrep
  tree
  tmux
  unzip
  zsh-powerlevel10k
  _1password-cli
  hl-log-viewer
  sd
  # ipcalc  # Temporarily disabled due to nokogiri compilation issues on macOS
  rename
  just
  websocat
  netcat-gnu
  unixtools.watch
  zellij
  yazi
  starship

  # Kubernetes k8s
  kubectl
  kubernetes-helm
  kubelogin-oidc
  helm-ls
  k9s
  krew
  kind
  kubectx

  # Development tools
  curl
  doggo
  gh
  lazygit
  jujutsu
  fzf
  direnv
  cloc
  mongosh
  mongodb-tools

  # Programming languages and runtimes
  go
  rustc
  cargo
  rust-analyzer
  rustfmt
  clippy
  openjdk
  yaml-language-server

  # Python packages
  python3
  virtualenv
  uv
]
