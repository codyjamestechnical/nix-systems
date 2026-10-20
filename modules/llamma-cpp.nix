{config, pkgs, lib, ...}:
{
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp-vulkan;
    # package = (pkgs.llama-cpp.override { cudaSupport = true; })
    # package = pkgs.llama-cpp-rocm;

    # Takes care of downloading if model not present
    modelsPreset = {
      
      "Gemma-4-12B-TurboQuant-GGUF" = {
        # Extract from the model URL on HuggingFace
        hf-repo = "majentik/gemma-4-12B-TurboQuant-GGUF-Q5_K_M";

        # Click on a quantization (e.g Q4_K_M) on HuggingFace to see the file name
        hf-file = "gemma-4-12B-Q5_K_M.gguf";  
        
        # Display name on llama UI
        alias = "majentik/gemma-4-12B-TurboQuant-GGUF-Q5_K_M";

        # Optimization parameters
        # temp = "0.2";
        # repeat-penalty = "1.05";
        # top-k = "80";
      };
     
    };
  };
}