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
            ripgrep
            ast-grep

            uv
            bun

            aichat
            ctx7
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
          ])
          ++ [
            git-ai.minimal
          ];
      };
    };
}
