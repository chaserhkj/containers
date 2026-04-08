{
  perSystem = {pkgs, ...}: {
    images.nfs-ganesha = {
      name = "ghcr.io/chaserhkj/containers/nfs-ganesha";
      tag = "latest";
      config = with pkgs; let
        ganeshaWithoutRPCBind = nfs-ganesha.overrideAttrs (
          oldAttrs: {
            cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
              "-D_NO_TCP_REGISTER=ON"
              "-DRPCBIND=OFF"
            ];
          }
        );
      in {
        Entrypoint = [ 
          "${tini}/bin/tini" "--"
          "${ganeshaWithoutRPCBind}/bin/ganesha.nfsd"
        ];
        Cmd = [
          "-F" "-x" "-L" "/dev/stdout" "-f"
          "/config/ganesha.conf"
        ];
      };
      copyToRoot = pkgs.runCommand "runtime-fs" {} ''
        mkdir -p $out/var/run/ganesha
        mkdir -p $out/export
      '';
    };
  };
}