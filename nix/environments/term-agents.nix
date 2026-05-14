{...}: {
  perSystem = {inputs', pkgs, ...}: {
    devshellContainers.term-agent = {};
    devshells.term-agent = {
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