# Reusable one-shot systemd service that creates a docker network on boot
# and removes it on stop.
#
# This defines a top-level systemd service, so it CANNOT be added to the
# `containers` attrset. Add it to the module's `imports` list instead:
#
#   imports = [ (import ./docker-network.nix { inherit cfg; }) ];
#
# It is a curried module: it takes `{ cfg }` and returns a NixOS module, so
# `pkgs` is supplied automatically by the module system.
#
# Expected `cfg` fields:
#   network_name - name of the docker network to manage (required)
#
# Optional `cfg` fields (with defaults):
#   network_ipv6         - enable IPv6 on the network (default true)
#   network_extra_args   - extra args passed to `docker network create` (default "")

{ cfg }:

{ pkgs, ... }:

let
  ipv6Arg = if (cfg.network_ipv6 or true) then " --ipv6" else "";
  extraArgs = cfg.network_extra_args or "";
  createArgs = ipv6Arg + (if extraArgs != "" then " ${extraArgs}" else "");
in
{
  systemd.services."docker-network-${cfg.network_name}" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f ${cfg.network_name}";
    };
    script = ''
      docker network inspect ${cfg.network_name} || docker network create ${cfg.network_name}${createArgs}
    '';

    wantedBy = [ "multi-user.target" ];
  };
}
