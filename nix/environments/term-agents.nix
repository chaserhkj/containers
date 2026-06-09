{...}: {
  perSystem = {inputs', pkgs, self', ...}: {
    devshellContainers.term-agents = {};
    devshells.term-agents = {
      packages = let 
        llm = inputs'.llm-agents.packages;
      in (with pkgs; [
        git
        curl
        jq

        uv
        bun
        (writeShellScriptBin "npx" ''
          exec ${bun}/bin/bunx "$@"
        '')
      ])++(with llm; [
        opencode

        openskills
        tuicr
        ck
      ]) ++ (with self'.packages; [
        open-code-review
      ]);
    };
  };
}