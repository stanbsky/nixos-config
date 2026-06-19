{ user, config, pkgs, ... }:

let
  xdg_configHome = "${config.users.users.${user}.home}/.config";
  xdg_dataHome   = "${config.users.users.${user}.home}/.local/share";
  xdg_stateHome  = "${config.users.users.${user}.home}/.local/state"; in
{

  # Raycast/Emacs launcher — disabled while emacs is out of the build
  # "${xdg_dataHome}/bin/emacsclient" = {
  #   executable = true;
  #   text = ''
  #     #!/bin/zsh
  #     if [[ $1 = "-t" ]]; then
  #       ${pkgs.emacs}/bin/emacsclient -t $@
  #     else
  #       ${pkgs.emacs}/bin/emacsclient -c -n $@
  #     fi
  #   '';
  # };
}
