{
  perSystem = {pkgs, ...}: with pkgs; let
        ganeshaInputConfigured = nfs-ganesha.override {
          useCeph = false;
          useDbus = false;
        };
        ganeshaConfigured = ganeshaInputConfigured.overrideAttrs (
          oldAttrs: {
            outputs = ["out"];
            meta = oldAttrs.meta // {
              outputsToInstall = ["out"];
            };
            patches = (oldAttrs.patches or []) ++ [];
            # Patch out post install hooks that installs 9P and dbus files
            postInstall = "";
            cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
              # Disable other protocols and only leave NFS4/RDMA
              "-DUSE_9P=OFF"
              "-DUSE_NFS3=OFF"
              "-DUSE_RQUOTA=OFF"
              "-DUSE_NFS4=ON"
              "-DUSE_NFS_RDMA=ON"
              # Enabled features
              "-DUSE_FSAL_VFS=ON"
              "-DUSE_FSAL_PROXY_V4=ON"
              "-DENABLE_VFS_POSIX_ACL=ON"
              "-DUSE_ACL_MAPPING=ON"
              "-DUSE_MONITORING=ON"
              "-DUSE_CAPS=ON"
              # Disable rpcbind and portmapper for NFS4 only
              "-D_NO_TCP_REGISTER=ON"
              "-DRPCBIND=OFF"
              # Unused features
              "-DUSE_DBUS=OFF"
              "-DUSE_ADMIN_TOOLS=OFF"
              "-DUSE_GUI_ADMIN_TOOLS=OFF"
              "-DUSE_RADOS_RECOV=OFF"
              "-DUSE_GSS=OFF"
              "-DUSE_MAN_PAGE=OFF"
              "-DUSE_NFSIDMAP=OFF"
              # Unused FSAL drivers
              "-DUSE_FSAL_PROXY_V3=OFF"
              "-DUSE_FSAL_LUSTRE=OFF"
              "-DUSE_FSAL_LIZARDFS=OFF"
              "-DUSE_FSAL_KVSFS=OFF"
              "-DUSE_FSAL_CEPH=OFF"
              "-DUSE_FSAL_RGW=OFF"
              "-DUSE_FSAL_SAUNAFS=OFF"
              "-DUSE_FSAL_XFS=OFF"
              "-DUSE_FSAL_GPFS=OFF"
              "-DUSE_FSAL_GLUSTER=OFF"
              "-DUSE_FSAL_NULL=OFF"
              "-DUSE_FSAL_MEM=OFF"
            ];
          }
        );
    in {
    containers.nfs-ganesha = {
      name = "ghcr.io/chaserhkj/containers/nfs-ganesha";
      tag = "latest";
      config = {
        Entrypoint = [ 
          "${tini}/bin/tini" "--"
          "${ganeshaConfigured}/bin/ganesha.nfsd"
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
      buildFixedEntrypointVariant = true;
      passthru = {
        ganesha = ganeshaConfigured;
      };
    };
  };
}