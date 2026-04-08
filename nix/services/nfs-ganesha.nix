{
  perSystem = {pkgs, ...}: {
    images.nfs-ganesha = {
      name = "ghcr.io/chaserhkj/containers/nfs-ganesha";
      tag = "latest";
      config = with pkgs; {
        Entrypoint = [ 
          "${tini}/bin/tini" "--"
          "${nfs-ganesha}/bin/ganesha.nfsd"
        ];
        Cmd = [
          "-F" "-x" "-L" "/dev/stdout" "-f"
          "/config/ganesha.conf"
        ];
      };
      copyToRoot = pkgs.runCommand "runtime-fs" {} ''
        mkdir -p $out/var/run/ganesha
      '';
    };
  };
}