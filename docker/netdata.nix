{ config, pkgs, ...}:
{
    # Docker Containers
    virtualisation.oci-containers = {
        containers = {
            netdata = {
                image = "netdata/netdata:edge";
                log-driver = "local";
                volumes = [
                    "netdataconfig:/etc/netdata"
                    "netdatalib:/var/lib/netdata"
                    "/:/host/root:ro,rslave"
                    "netdatacache:/var/cache/netdata"
                    "/etc/passwd:/host/etc/passwd:ro"
                    "/etc/group:/host/etc/group:ro"
                    "/etc/localtime:/etc/localtime:ro"
                    "/proc:/host/proc:ro"
                    "/sys:/host/sys:ro"
                    "/etc/os-release:/host/etc/os-release:ro"
                    "/var/log:/host/var/log:ro"
                    "/var/run/docker.sock:/var/run/docker.sock:ro"
                    "/run/dbus:/run/dbus:ro"
                ];
                extraOptions = ["--network=host" "--pid=host" "--cap-add SYS_ADMIN" "--security-opt apparmor=unconfined"];
                environmentFiles = [ "/var/secrets/netdata-env" ];

                labels = {"komodo.skip" = "";};
            };
        };
    };
}