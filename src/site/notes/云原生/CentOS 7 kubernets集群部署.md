---
{"dg-publish":true,"page-title":"CentOS 7 kubernetes + containerd + calico basic installation tutorial | omegaatt","url":"https://www.omegaatt.com/blogs/develop/2022/centos-7-kubernetes-install/","tags":["k8s/pratice"],"permalink":"/云原生/CentOS 7 kubernets集群部署/","dgPassFrontmatter":true}
---

转载自：https://www.omegaatt.com/blogs/develop/2022/centos-7-kubernetes-install/

本人根据实际情况对步骤进行了更改。

## 前言

鑒於最近接到 1 CentOS master + 2 Gentoo node k8s cluster 建置雜事，被自己不熟系統雷到，做個筆記紀錄一下，未來敲敲指令就可以了

```
                 ..                    root@master
               .PLTJ.                  -----------
              <><><><>                 OS: CentOS Linux 7 (Core) x86_64
     KKSSV' 4KKK LJ KKKL.'VSSKK        Host: KVM/QEMU (Standard PC (i440FX + PIIX, 1996) pc-i440fx-6.1)
     KKV' 4KKKKK LJ KKKKAL 'VKK        Kernel: 5.4.180-1.el7.elrepo.x86_64
     V' ' 'VKKKK LJ KKKKV' ' 'V        Uptime: 2 mins
     .4MA.' 'VKK LJ KKV' '.4Mb.        Packages: 359 (rpm)
   . KKKKKA.' 'V LJ V' '.4KKKKK .      Shell: bash 4.2.46
 .4D KKKKKKKA.'' LJ ''.4KKKKKKK FA.    Terminal: /dev/pts/0
<QDD ++++++++++++  ++++++++++++ GFD>   CPU: Common KVM processor (4) @ 3.493GHz
 'VD KKKKKKKK'.. LJ ..'KKKKKKKK FV     Memory: 97MiB / 16015MiB
   ' VKKKKK'. .4 LJ K. .'KKKKKV '
      'VK'. .4KK LJ KKA. .'KV'
     A. . .4KKKK LJ KKKKA. . .4
     KKA. 'KKKKK LJ KKKKK' .4KK
     KKSSA. VKKK LJ KKKV .4SSKK
              <><><><>
               'MKKM'
                 ''
```

此篇 CentOS 寄宿於 PVE 下，kernel 已升級為 `5.4.180-1.el7.elrepo.x86_64` 使用 containerd 作為 cri 使用 calico 作為 cni，並使用 host 唯一的網卡，不做其他進階設定。

# 基础流程
本章适用于Master Node 和 Worker Node

1.  安裝依賴

```
yum install -y conntrack iptables wget vim
```

2.  防火牆設成 `iptables`

```
systemctl stop firewalld && systemctl disable firewalld && yum -y remove firewalld
yum -y install iptables-services && systemctl start iptables && systemctl enable iptables
```

关闭防火墙
```shell
systemctl stop iptables
systemctl disable iptables
```

3.  关闭 swap

```
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

4.  关闭 SELINUX

```
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
```

5.  調整 kernel 參數

```
touch /etc/sysctl.d/kubernetes.conf
vim /etc/sysctl.d/kubernetes.conf
```

輸入下面內容

```
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
net.ipv4.tcp_tw_recycle=0
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
fs.file-max=52706963
fs.nr_open=52706963
net.ipv6.conf.all.disable_ipv6=1
net.netfilter.nf_conntrack_max=2310720
```

然後

```
sysctl -p /etc/sysctl.d/kubernetes.conf
```

6.  調整系統時區

```
timedatectl set-timezone Asia/Shanghai
timedatectl set-local-rtc 0
```

7.  ipvs 設定

```
modprobe br_netfilter
vim /etc/sysconfig/modules/ipvs.modules
```

主要是把 `nf_conntrack_ipv4` 改為 `nf_conntrack`

```
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack 
```

更改完後執行

```
chmod 755 /etc/sysconfig/modules/ipvs.modules
bash /etc/sysconfig/modules/ipvs.modules
lsmod | grep -e ip_vs -e nf_conntrack_ipv4
```

8.  安裝 containerd，改用 docker ce 作為 yum repo，因為踩到了 [containerd 版本過舊的坑](https://github.com/containerd/containerd/issues/4901)

```
yum install -y yum-utils device-mapper-persistent-data lvm2

yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install containerd -y

containerd config default > /etc/containerd/config.toml
```

修改containerd的配置文件

`vim /etc/containerd/config.toml` 設定 `SystemdCgroup = true`和`sandbox_image = "registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.6"` ，具体pause的版本号按照原先的设置即可，主要是把源修改为阿里云。


```shell
systemctl restart containerd
systemctl status containerd
systemctl enable containerd
```

编辑`vim /lib/systemd/system/containerd.service` 设置代理
```
[Service]
# 根据实际情况填写代理地址
Environment="HTTP_PROXY=http://192.168.6.1:7890" 
Environment="HTTPS_PROXY=http://192.168.6.1:7890"
Environment="NO_PROXY=localhost,127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.svc,.cluster.local,.ewhisper.cn,node,<nodeCIDR>,<APIServerInternalURL>,<serviceNetworkCIDRs>,<etcdDiscoveryDomain>,<clusterNetworkCIDRs>,<platformSpecific>,<REST_OF_CUSTOM_EXCEPTIONS>"
# 注意替换<>
```

```shell
systemctl daemon-reload
systemctl restart containerd
```

9. 安装crictl

```shell
VERSION="v1.30.0"
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/critest-$VERSION-linux-amd64.tar.gz
sudo tar zxvf critest-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f critest-$VERSION-linux-amd64.tar.gz
```

`vim /etc/crictl.yaml` 設定 cri 為 containerd

```bash
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
```

看看是否設定正常

```bash
crictl  pull nginx
crictl  images
crictl  rmi nginx
```




10. 配置k8s repo 


```shell
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
```

11. 设置ip与hostname以及hosts, 根据个人情况进行修改

主要文件有：
```
/etc/sysconfig/network-scripts/<net adapter>
/etc/hosts
/etc/hostname
```

# Master Node

本章往下的内容都是在master node上操作

12. 安装kubeadm kubelet kubectl
```
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet
```



13.  kubeadm 初始化 master node 先將 config 導出加以設置

```
kubeadm config print init-defaults > kubeadm-init.yaml
```

`vim kubeadm-config.yaml` 更改以下設置

```yaml
localAPIEndpoint:
  # master node 的 ip
  advertiseAddress: 192.168.6.100 # 根据实际情况修改
nodeRegistration:
  # 更改 continer runtime interface 為 containerd
  criSocket: unix:///run/containerd/containerd.sock
networking:
  podSubnet: "10.168.0.0/16"
  # cidr 在設定 calico 時會用到
  serviceSubnet: 10.96.0.0/16
imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers
```

`kubeadm init --config=kubeadm-init.yaml` 初始化 master node

訊息會提示你將 `/etc/kubernetes/admin.conf` 複製到 `$HOME/.kube/config`

```
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

並複製下面那一串加入指令以便其他 node 加入(兩個小時會過期)

> kubeadm join 192.168.6.100:6443 --token abcdef.0123456789abcdef \
        --discovery-token-ca-cert-hash sha256:5b228cae54bc6b09b429391ab88f0f28964c519c6265c5a74f533c545ab15080 或是使用 `kubeadm token create --print-join-command` 建立一個新的

14.  設定 calico 作為 cni

```shell
kubectl apply -f "https://docs.projectcalico.org/manifests/calico.yaml"
```

設定完成後可以透過 `watch -n 1 kubectl get pods -A` 查看 namespace `kube-system` 下的 pod 是否都正常 running

```
Every 1.0s: kubectl get pods -A                                                                                                                                                                                                     Sun Feb 20 17:19:56 2022

NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-566dc76669-dngc4   1/1     Running   0          125m
kube-system   calico-node-wg6dn                          1/1     Running   0          125m
kube-system   coredns-64897985d-h4n45                    1/1     Running   0          123m
kube-system   coredns-64897985d-tkxsw                    1/1     Running   0          123m
kube-system   etcd-node                                  1/1     Running   0          134m
kube-system   kube-apiserver-node                        1/1     Running   0          134m
kube-system   kube-controller-manager-node               1/1     Running   0          134m
kube-system   kube-proxy-vhq2j                           1/1     Running   0          134m
kube-system   kube-scheduler-node                        1/1     Running   0          134m
```

至此 master node 就順利設定完成了


# Worker Node


12. 安装kubeadm kubelet
```
yum install -y kubelet kubeadm --disableexcludes=kubernetes
systemctl enable --now kubelet
```

