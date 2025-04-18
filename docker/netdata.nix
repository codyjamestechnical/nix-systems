{ config, pkgs, ...}:
{
    # Docker Containers
    virtualisation.oci-containers = {
        backend = "docker";
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
                extraOptions = ["--network=host" "--pid=host" "--cap-add=sys_ptrace" "--cap-add=sys_admin"];
                environmentFiles = [ "/var/secrets/netdata-env" ];

                labels = {"komodo.skip" = "";};
            };
        };
    };
}