{ ... }: {
  perSystem =
    {
      inputs',
      pkgs,
      self',
      ...
    }:
    {
      devshellContainers.term-agents = { };
      devshells.term-agents = {
        packages =
          let
            llm = inputs'.llm-agents.packages;
            git-ai = inputs'.git-ai.packages;
          in
          (with pkgs; [
            git
            diffutils
            curl
            jq

            uv
            bun
            (writeShellScriptBin "npx" ''
              exec ${bun}/bin/bunx "$@"
            '')
          ])
          ++ (with llm; [
            opencode

            backlog-md
            tuicr

            ck
            qmd
            codegraph

            mcporter
            context-hub

            openskills
            skills
          ])
          ++ (with self'.packages; [
            cecli
            mozilla-cq
            open-code-review
          ])
          ++ [
            git-ai.minimal
          ];
      };
    };
}
