source conf
yum -y install nfs-utils
mkdir -p ${nfs_dir}
cat <<EOF > /etc/exports
${nfs_dir} *(rw,no_root_squash,sync)
EOF

exportfs -r
systemctl restart rpcbind && systemctl enable rpcbind
systemctl restart nfs && systemctl enable nfs
helm install nfs ./nfs --set nfs.server=${myip} --set nfs.path=${nfs_dir} -n ${namespace}