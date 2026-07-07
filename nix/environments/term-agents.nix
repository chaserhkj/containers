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
            pi
            hermes-agent

            backlog-md
            tuicr

            ck
            qmd
            codegraph
            semble

            mcporter
            context-hub

            openskills
            skills

            agent-browser
            rtk
            terminal-use
          ])
          ++ (with self'.packages; [
            openkb
            graphrag
            llm-wiki-compiler
            mozilla-cq
            open-code-review
            opencommit
          ])
          ++ [
            git-ai.minimal
          ];
      };
    };
}
