{config, pkgs, lib, ...}:
{
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp-vulkan;
    settings = {
      host = "0.0.0.0";
      # port = "9080";
    };
    
    openFirewall = true;
    # package = (pkgs.llama-cpp.override { cudaSupport = true; })
    # package = pkgs.llama-cpp-rocm;

  };
}