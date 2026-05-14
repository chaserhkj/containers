{...}: {
  perSystem = {inputs', pkgs, ...}: {
    devshellContainers.term-agents = {};
    devshells.term-agents = {
      packages = let 
        llm = inputs'.llm-agents.packages;
      in (with pkgs; [
        git
        curl
      ])++(with llm; [
        opencode

        openskills
        tuicr
        ck
      ]);
    };
  };
}