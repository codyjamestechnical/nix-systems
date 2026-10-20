{config, pkgs, lib, ...}:
{
  environment.systemPackages = with pkgs; [
    llama-cpp-rocm
  ];
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp-rocm;
    settings = {
      host = "0.0.0.0";
      port = 9080;
      model = "/docker-data/gemma-4-12B-Q5_K_M.gguf"
    };
    
    openFirewall = true;
    # package = (pkgs.llama-cpp.override { cudaSupport = true; })
    # package = pkgs.llama-cpp-rocm;

  };
}