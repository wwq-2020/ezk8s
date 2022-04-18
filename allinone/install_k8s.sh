source conf
systemctl stop firewalld && systemctl disable firewalld

setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

swapoff -a
sed -i '/swap/s/^\(.*\)$/#\1/g' /etc/fstab

iptables -F && iptables -X && iptables \
    -F -t nat && iptables -X -t nat && iptables -P FORWARD ACCEPT

cat <<EOF >>  /etc/sysctl.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl -p


cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
       http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF


yum install -y kubeadm kubelet kubectl


systemctl enable kubelet && systemctl start kubelet


docker pull registry.aliyuncs.com/google_containers/pause:3.6
docker tag registry.aliyuncs.com/google_containers/pause:3.6 k8s.gcr.io/pause:3.6
docker rmi registry.aliyuncs.com/google_containers/pause:3.6






kubeadm init  --kubernetes-version=v1.23.5  --apiserver-advertise-address=${myip} --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers --pod-network-cidr=${cidr}  --v=5 
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
kubectl taint node ${HOSTNAME,,} node-role.kubernetes.io/master-

## prepare network
kubectl apply -f k8s/kube-flannel.yml


## prepare namespace
kubectl create ns ${namespace}

echo "source <(kubectl completion bash)">>$HOME/.bashrc
