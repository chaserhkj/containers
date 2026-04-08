{
  perSystem = {pkgs, ...}: {
    image.nfs-ganesha = {
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
    };
  };
}