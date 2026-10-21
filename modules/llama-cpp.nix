{config, pkgs, lib, ...}:
{
  environment.systemPackages = with pkgs; [
    llama-cpp-vulkan
  ];
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp-vulkan;
    settings = {
      host = "0.0.0.0";
      port = 9080;
      model = "/docker-data/gemma-4-E2B-Q8_0.gguf";
    };
    
    openFirewall = true;

  };
}