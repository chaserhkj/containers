{...}: {
  perSystem = {inputs', pkgs, ...}: {
    devshellContainers.term-agents = {};
    devshells.term-agents = {
      packages = let 
        llm = inputs'.llm-agents.packages;
      in (with pkgs; [
        git
        curl

        aider-chat
      ])++(with llm; [
        opencode

        openskills
        tuicr
        ck
      ]);
    };
  };
}