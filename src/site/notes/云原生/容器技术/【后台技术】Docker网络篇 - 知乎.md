---
{"dg-publish":true,"page-title":"【后台技术】Docker网络篇 - 知乎","url":"https://zhuanlan.zhihu.com/p/683336819","tags":["云原生/docker","linux/net"],"permalink":"/云原生/容器技术/【后台技术】Docker网络篇 - 知乎/","dgPassFrontmatter":true}
---

转载自： https://zhuanlan.zhihu.com/p/683336819 

接上文 [鹅厂架构师：【后台技术】Docker基础篇](https://zhuanlan.zhihu.com/p/683330478) 。本文介绍Docker的网络，包括网桥，Overlay等。

## 第一部分：Docker网络

Docker网络需要处理容器之间，容器与外部网络和VLAN之间的连接，设置之初相对复杂，随着容器化的发展，Docker网络架构采用容器网络模型方案（CNM），支持拔插式的驱动方式来提供网络拓扑。

### 1、详解

**（1）CNM**

Docker的网络架构设计规范是CNM，CNM规定了基本组成要素：

-   沙盒：是一种独立的网络栈，包括以太网接口，端口，路由以及DNS配置
-   终端（EP）：虚拟网络接口，负责创建连接，将沙盒连接到网络
-   网络：网桥的软件实现

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202402292102991.jpeg)

**（2）Libnetwork**

Libnetwork是CNM的标准实现，支持跨平台，3个标准的组件和服务发现，基于Ingress的容器负载均衡，以及网络控制层和管理层的功能。

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202402292102993.jpeg)

**（3）网络模式**

[[计算机网络/集线器、网桥、交换机的区别（详解干货！！！） - 知乎\|集线器、网桥、交换机的区别（详解干货！！！） - 知乎]]

**网桥（Bridge）**：Docker默认的容器网络驱动，容器通过一对veth pair连接到docker0网桥上，由Docker为容器动态分配IP及配置路由、防火墙规则等，具体详解可以查看第二部分；

**Host**：容器与主机共享同一Network Namespace，共享同一套网络协议栈、路由表及iptables规则等，执行`docker run --net=host centos:7 python -m SimpleHTTPServer 8081`，然后查看看网络情况(`netstat -tunpl`) :

```
[root@VM-16-16-centos ~]# netstat -tunpl
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:8081            0.0.0.0:*               LISTEN      1409899/python
```

可以看出host模型下，和主机上启动一个端口没有差别，也不会做端口映射，所以不同的服务在主机端口范围内不能冲突；

**Overlay**：多机覆盖网络是Docker原生的跨主机多子网网络方案，主要通过使用Linux bridge和vxlan隧道([[计算机网络/什么是VXLAN - 华为\|什么是VXLAN - 华为]])实现，底层通过类似于etcd或consul的KV存储系统实现多机的信息同步，具体详解可以看第二部分；

**Remote**：Docker网络插件的实现，可以借助Libnetwork实现网络自己的网络插件；

**None**：模式是最简单的网络模式，它会使得Docker容器完全隔离，无法访问外部网络。在None模式下，容器不会被分配IP地址，也无法与其他容器和主机通信，可以尝试执行`docker run --net=none centos:7 python -m SimpleHTTPServer 8081`，然后`curl xxx.com`应该是无法访问的。

## 第二部分：网桥和Overlay详解

Docker中最常用的两种网络是网桥和Overlay，网桥是解决主机内多容器通讯，Overlay是解决跨主机多子网网络，下面我们来详细了解一下这两种网络模式。

### 1、网桥（Bridge）

网桥是什么？同`tap/tun`、`veth-pair`一样，网桥是一种虚拟网络设备，所以具备虚拟网络设备的所有特性，比如可以配置IP、MAC等，除此之外，网桥还是一个二层交换机，具有交换机所有的功能。

**（1）创建**

`Docker daemon`启动时会在主机创建一个Linux网桥（默认为`docker0`），容器启动时，Docker会创建一对`veth-pair`（虚拟网络接口）设备，`veth`设备的特点是成对存在，从一端进入的数据会同时出现在另一端，Docker会将一端挂载到docker0网桥上，另一端放入容器的Network Namespace内，从而实现容器与主机通信的目的。

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202402292102994.jpeg)

**（2）查看网桥**

执行`docker network ls`，输出：

```
[root@VM-16-16-centos ~]# docker network ls
NETWORK ID     NAME              DRIVER    SCOPE
839c78d16e66   bridge            bridge    local
7865e8dc7489   host              host      local
e904b639a46d   k3d-k3d-private   bridge    local
e6e4904ea322   none              null      local
```

**（3）查看网桥的详细信息**

先执行`docker run -d --name busybox-1 busybox echo "1"`和`docker run -d --name busybox-2 busybox echo "2"`，然后执行`docker inspect bridge`，可以看到输出网桥IPv4Address，MacAddress和EndpointID等：

```
"Containers": {
    "bbd7d0775081dd9a9d026ca4c8e3ec2e1a4b19bead122eac94cd58f1fa118827": {
        "Name": "busybox-2",
        "EndpointID": "a82be8a01e25f5267fd6286c10eb1c72a1dd1c1933dcc84a82b286162767923c",
        "MacAddress": "02:42:ac:11:00:03",
        "IPv4Address": "172.17.0.3/16",
        "IPv6Address": ""
    },
    "fa14fa3e167d17922a94153c0e0eb83e244ef7b20f9fc04d05db2589828e747c": {
        "Name": "busybox-1",
        "EndpointID": "90f614cc4b2e4c5d2baa75facfa8e493d287cbb9ae39edaecb3ec67915d2df2b",
        "MacAddress": "02:42:ac:11:00:02",
        "IPv4Address": "172.17.0.2/16",
        "IPv6Address": ""
    }
}
```

**（4）探测网桥是否正常**

可以进入busybox-2容器，执行`ping 172.17.0.2`，输出（可见是可以通的）：

```
PING 172.17.0.2 (172.17.0.2): 56 data bytes
64 bytes from 172.17.0.2: seq=0 ttl=64 time=0.115 ms
64 bytes from 172.17.0.2: seq=1 ttl=64 time=0.079 ms
64 bytes from 172.17.0.2: seq=2 ttl=64 time=0.051 ms
64 bytes from 172.17.0.2: seq=3 ttl=64 time=0.066 ms
64 bytes from 172.17.0.2: seq=4 ttl=64 time=0.051 ms
^C
--- 172.17.0.2 ping statistics ---
5 packets transmitted, 5 packets received, 0% packet loss
round-trip min/avg/max = 0.051/0.072/0.115 ms
```

**（5）端口映射**

基于上面我们已经了解容器与容器之间的通讯，那么Docker端口映射是如何通讯的呢？先执行 `docker run -d -p 8000:8000 centos:7 python -m SimpleHTTPServer` 建立映射关系，然后查看 `iptables`，执行`iptables -t nat -nvL`：

```
[root@VM-16-16-centos ~]# iptables -t nat -nvL
Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
 203K 7590K DOCKER     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL

Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 MASQUERADE  all  --  *      !docker0  172.17.0.0/16        0.0.0.0/0
   26  1680 MASQUERADE  all  --  *      !br-e904b639a46d  172.18.0.0/16        0.0.0.0/0
    0     0 MASQUERADE  tcp  --  *      *       172.18.0.2           172.18.0.2           tcp dpt:6443
    0     0 MASQUERADE  tcp  --  *      *       172.17.0.5           172.17.0.5           tcp dpt:8000

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 DOCKER     all  --  *      *       0.0.0.0/0           !127.0.0.0/8          ADDRTYPE match dst-type LOCAL

Chain DOCKER (2 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 RETURN     all  --  docker0 *       0.0.0.0/0            0.0.0.0/0
    0     0 RETURN     all  --  br-e904b639a46d *       0.0.0.0/0            0.0.0.0/0
    0     0 DNAT       tcp  --  !br-e904b639a46d *       0.0.0.0/0            0.0.0.0/0            tcp dpt:37721 to:172.18.0.2:6443
    0     0 DNAT       tcp  --  !docker0 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8000 to:172.17.0.5:8000
```

可以看出只要是非docker0进来的数据包（如`eth0`进来的数据），都是8000直接转到172.17.0.5:8000，可以看出这里是借助`iptables`实现的。

**（6）网桥模式下的Docker网络流程**

-   容器与容器之前通讯是通过`Network Namespace, bridge和veth pair`这三个虚拟设备实现一个简单的二层网络，不同的namespace实现了不同容器的网络隔离让他们分别有自己的ip，通过`veth pair`连接到`docker0`网桥上实现了容器间和宿主机的互通；
-   容器与外部或者主机通过端口映射通讯是借助`iptables`，通过路由转发到`docker0`，容器通过查询`CAM`表，或者`UDP`广播获得指定目标地址的MAC地址，最后将数据包通过指定目标地址的连接在`docker0`上的`veth pair`设备，发送到容器内部的`eth0`网卡上；
-   容器与外部或者主机通过端口映射通讯对应的限制是相同的端口不能在主机下重复映射；

### 2、Overlay

[[计算机网络/什么是VXLAN - 华为\|什么是VXLAN - 华为]]

在云原生下集群通讯是必须的，当然Docker提供多种方式，包括借助Macvlan接入VLAN网络，另一种是Overlay。那什么是Overlay呢？指的就是在物理网络层上再搭建一层网络，通过某种技术再构建一张相同的逻辑网络。

**（1）原理**

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202402292102995.jpeg)

在讲原理之前先了解一下VXLAN网络，什么VXLAN网络？VXLAN全称是Visual eXtensible Local Area Network，本质上是一种隧道封装技术，它使用封装/解封装技术，将L2的以太网帧（Ethernet frames）封装成L4的UDP数据报（datagrams），然后在L3的网络中传输，效果就像L2的以太网帧在一个广播域中传输一样，实际上是跨越了L3网络，但却感知不到L3网络的存在。 那么容器B发送请求给容器A（ping）的具体流程是怎样的？

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202402292102996.jpeg)

-   1.容器B执行ping，流量通过BridgeB的veth接口发送出去，但是这个时候BridgeB并不知道要发送到哪里（BridgeB没有MAC与容器A的IP映射表），所以BridgeB将通过VTEP解析ARP协议，确定MAC和IP以后，将真正的数据包转发给VTEP，带上VTEP的MAC地址
-   2.VTEP-B收到数据包，通过Swarm的集群的网络信息中知道目标IP是容器A
-   3.VTEP-B将数据包封装为VXLAN格式（数据包中存储了VXLAN的ID，记录其映射关系）
-   4.实际底层VTEP-B将数据包通过主机B的UDP物理通道将VXLAN数据包封装为UDP发送出去
-   5-6.通过隧道传输（UDP端口：4789），数据包到达VTEP-A，VTEP-A解析数据包读取其中的VXLAN的ID，确定发送到哪个网桥
-   7.VTEP-A继续解包和封包，将数据从UDP中拆解出来，重新组装网络协议包，发送给BridgeA
-   8.BridgeA收到数据，通过veth发给容器A，回包的过程就是反向处理

**（2）创建（Overlay）**

执行`docker swarm init`，然后创建test-net（`docker network create --subnet=10.1.1.0/24 --subnet=11.1.1.0/24 -d overlay test-net`），查看网络创建情况：

```
[root@VM-16-16-centos ~]# docker network ls
NETWORK ID     NAME              DRIVER    SCOPE
839c78d16e66   bridge            bridge    local
d35cd7f611a6   docker_gwbridge   bridge    local
7865e8dc7489   host              host      local
kxda014niohv   ingress           overlay   swarm
e904b639a46d   k3d-k3d-private   bridge    local
e6e4904ea322   none              null      local
20miz5lia741   test-net          overlay   swarm
```

发现最后一行test-net创建成功。然后创建一个sevice，replicas等于2来看看网络情况，执行（`docker service create --name test --network test-net --replicas 2 centos:7 sleep infinity`），由于有两台物理机器，可以看看网络和服务情况：

```
# 第一台物理机器
[root@VM-16-16-centos ~]# docker ps -a
CONTAINER ID   IMAGE    COMMAND         CREATED         STATUS  PORTS   NAMES
32e4ada62916   centos:7 "sleep infinity"    3 minutes ago   Up 3 minutes   test.2.5j5bm8m0g96enm3ltf7172rt4

[root@VM-16-16-centos ~]# docker network ls
NETWORK ID     NAME              DRIVER    SCOPE
839c78d16e66   bridge            bridge    local
d35cd7f611a6   docker_gwbridge   bridge    local
7865e8dc7489   host              host      local
kxda014niohv   ingress           overlay   swarm
e904b639a46d   k3d-k3d-private   bridge    local
e6e4904ea322   none              null      local
20miz5lia741   test-net          overlay   swarm

# 第二台物理机器
[root@VM-0-11-centos ~]# docker ps -a
CONTAINER ID      IMAGE COMMAND    CREATED   STATUS  PORTS    NAMES
a59a6f6dd333       centos@sha256:be65f488b7764ad3638f236b7b515b3678369a5124c47b8d32916d6487418ea4   "sleep infinity"    4 minutes ago   Up 4 minutes   test.1.braoj968z1jm5bc22e2k63he1

[root@VM-0-11-centos ~]# docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
d5d11ce155e2        bridge              bridge              local
f4c92d6c36ad        docker_gwbridge     bridge              local
e6a370238ef2        host                host                local
828150052a2a        mongodb_default     bridge              local
71347f42b9a6        none                null                local
20miz5lia741        test-net            overlay             swarm
```

**（3）查看网络详情并测试**

创建成功后，可以查看一下网络详情，执行`docker network inspect test-net`，输出如下：

```
# 第一台物理机
[
    {
        "Name": "test-net",
        "Id": "20miz5lia7413mzkyhjokwu1h",
        "Created": "2023-09-09T11:45:32.325811853+08:00",
        "Scope": "swarm",
        "Driver": "overlay",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "11.1.1.0/24",
                    "Gateway": "11.1.1.1"
                },
                {
                    "Subnet": "10.1.1.0/24",
                    "Gateway": "10.1.1.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {
            "32e4ada62916b7d1070ae3c01f4306959ca5d093d60956f827210ca875e932d9": {
                "Name": "test.2.5j5bm8m0g96enm3ltf7172rt4",
                "EndpointID": "3f8071a94d60c6efc5d3505e73c65abe5a282d291362ea3e3986d4b78505a41f",
                "MacAddress": "02:42:0a:01:01:07",
                "IPv4Address": "10.1.1.7/24",
                "IPv6Address": ""
            },
            "lb-test-net": {
                "Name": "test-net-endpoint",
                "EndpointID": "0a20f5b5b756b8b50d319fa86fe870f5064fef22fc4583f2779f540718d22e4e",
                "MacAddress": "02:42:0b:01:01:0e",
                "IPv4Address": "11.1.1.14/24",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.driver.overlay.vxlanid_list": "4097,4098"
        },
        "Labels": {},
        "Peers": [
            {
                "Name": "VM-0-11-centos-7305e151739f",
                "IP": "172.27.0.11"
            },
            {
                "Name": "2bced4fe04a3",
                "IP": "172.27.16.16"
            }
        ]
    }
]

# 第二台物理机
[
    {
        "Name": "test-net",
        "Id": "20miz5lia7413mzkyhjokwu1h",
        "Created": "2023-09-09T11:39:30.639389025+08:00",
        "Scope": "swarm",
        "Driver": "overlay",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "11.1.1.0/24",
                    "Gateway": "11.1.1.1"
                },
                {
                    "Subnet": "10.1.1.0/24",
                    "Gateway": "10.1.1.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Containers": {
            "a59a6f6dd3330a618898548b147c901c1fb9c38d86ac2308e8a89de52bf60825": {
                "Name": "test.1.braoj968z1jm5bc22e2k63he1",
                "EndpointID": "b46b9f436dd04aa0effddf1a11b093589c9583a8f42086323dbc0d5bea28083e",
                "MacAddress": "02:42:0b:01:01:0c",
                "IPv4Address": "11.1.1.12/24",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.driver.overlay.vxlanid_list": "4097,4098"
        },
        "Labels": {},
        "Peers": [
            {
                "Name": "VM-0-11-centos-7305e151739f",
                "IP": "172.27.0.11"
            },
            {
                "Name": "2bced4fe04a3",
                "IP": "172.27.16.16"
            }
        ]
    }
]
```

可以看到两个网络地址（Containers的值）分别是`10.1.1.7`和`11.1.1.12`，然后登陆到第一台机器（10.1.1.7），执行`ping 11.1.1.12 -c 1`发现可以成功，那么继续在第二台（11.1.1.12）抓包看看输出：

```
sh-4.2# tcpdump -i any
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on any, link-type LINUX_SLL (Linux cooked), capture size 262144 bytes
04:12:03.060571 IP test.2.5j5bm8m0g96enm3ltf7172rt4.test-net > a59a6f6dd333: ICMP echo request, id 10, seq 1, length 64
04:12:03.060600 IP a59a6f6dd333 > test.2.5j5bm8m0g96enm3ltf7172rt4.test-net: ICMP echo reply, id 10, seq 1, length 64
04:12:03.060966 IP localhost.48641 > 127.0.0.11.32849: UDP, length 39
04:12:03.061104 IP 127.0.0.11.domain > localhost.48641: 1204 1/0/0 PTR test.2.5j5bm8m0g96enm3ltf7172rt4.test-net. (115)
04:12:03.061219 IP localhost.60318 > 127.0.0.11.32849: UDP, length 41
04:12:03.061371 IP a59a6f6dd333.47196 > 183.60.82.98.domain: 32335+ PTR? 11.0.0.127.in-addr.arpa. (41)
04:12:03.061647 IP 183.60.82.98.domain > a59a6f6dd333.47196: 32335 NXDomain 0/1/0 (100)
04:12:03.061712 IP 127.0.0.11.domain > localhost.60318: 32335 NXDomain 0/1/0 (100)
04:12:03.062483 IP localhost.55382 > 127.0.0.11.32849: UDP, length 43
04:12:03.062616 IP a59a6f6dd333.60943 > 183.60.82.98.domain: 27860+ PTR? 98.82.60.183.in-addr.arpa. (43)
04:12:03.062783 IP 183.60.82.98.domain > a59a6f6dd333.60943: 27860 NXDomain 0/1/0 (107)
04:12:03.062830 IP 127.0.0.11.domain > localhost.55382: 27860 NXDomain 0/1/0 (107)
04:12:03.062996 IP localhost.35418 > 127.0.0.11.32849: UDP, length 41
04:12:03.063132 IP a59a6f6dd333.44914 > 183.60.82.98.domain: 62145+ PTR? 2.0.19.172.in-addr.arpa. (41)
04:12:03.063304 IP 183.60.82.98.domain > a59a6f6dd333.44914: 62145 NXDomain 0/1/0 (100)
```

从上述的抓包可以看出`test.2.5j5bm8m0g96enm3ltf7172rt4.test-ne`往当前服务发送ICMP报文并成功响应。

**（4）验证VXLAN隧道传输数据**

为了第一节的原理：通过VXLAN隧道传输，于是抓包，先在`10.1.1.12`容器上启动`python -m SimpleHTTPServer`，然后在`10.1.1.7`上发送curl命令`curl '11.1.1.12:8000'`，同时在`10.1.1.12`容器所在的主机2抓包udp端口`4789`，执行`tcpdump -i any port 4789`，输出如下：

```
[root@VM-0-11-centos ~]# tcpdump -i any port 4789
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on any, link-type LINUX_SLL (Linux cooked), capture size 262144 bytes
12:33:43.574034 IP 172.27.16.16.43908 > VM-0-11-centos.4789: VXLAN, flags [I] (0x08), vni 4097
IP 10.1.1.7.34786 > 11.1.1.12.irdmi: Flags [S], seq 2425839577, win 28200, options [mss 1410,sackOK,TS val 2424960080 ecr 0,nop,wscale 7], length 0
12:33:43.574142 IP VM-0-11-centos.49343 > 172.27.16.16.4789: VXLAN, flags [I] (0x08), vni 4098
IP 11.1.1.12.irdmi > 10.1.1.7.34786: Flags [S.], seq 841191230, ack 2425839578, win 27960, options [mss 1410,sackOK,TS val 3343949171 ecr 2424960080,nop,wscale 7], length 0
12:33:43.575033 IP 172.27.16.16.43908 > VM-0-11-centos.4789: VXLAN, flags [I] (0x08), vni 4097
IP 10.1.1.7.34786 > 11.1.1.12.irdmi: Flags [.], ack 1, win 221, options [nop,nop,TS val 2424960081 ecr 3343949171], length 0
12:33:43.575064 IP 172.27.16.16.43908 > VM-0-11-centos.4789: VXLAN, flags [I] (0x08), vni 4097
IP 10.1.1.7.34786 > 11.1.1.12.irdmi: Flags [P.], seq 1:79, ack 1, win 221, options [nop,nop,TS val 2424960081 ecr 3343949171], length 78
12:33:43.575084 IP VM-0-11-centos.49199 > 172.27.16.16.4789: VXLAN, flags [I] (0x08), vni 4098
IP 11.1.1.12.irdmi > 10.1.1.7.34786: Flags [.], ack 79, win 219, options [nop,nop,TS val 3343949172 ecr 2424960081], length 0
12:33:43.575732 IP VM-0-11-centos.49199 > 172.27.16.16.4789: VXLAN, flags [I] (0x08), vni 4098
IP 11.1.1.12.irdmi > 10.1.1.7.34786: Flags [P.], seq 1:18, ack 79, win 219, options [nop,nop,TS val 3343949173 ecr 2424960081], length 17
12:33:43.575822 IP VM-0-11-centos.49199 > 172.27.16.16.4789: VXLAN, flags [I] (0x08), vni 4098
IP 11.1.1.12.irdmi > 10.1.1.7.34786: Flags [FP.], seq 18:956, ack 79, win 219, options [nop,nop,TS val 3343949173 ecr 2424960081], length 938
12:33:43.576483 IP 172.27.16.16.43908 > VM-0-11-centos.4789: VXLAN, flags [I] (0x08), vni 4097
IP 10.1.1.7.34786 > 11.1.1.12.irdmi: Flags [.], ack 18, win 221, options [nop,nop,TS val 2424960083 ecr 3343949173], length 0
12:33:43.576555 IP 172.27.16.16.43908 > VM-0-11-centos.4789: VXLAN, flags [I] (0x08), vni 4097
IP 10.1.1.7.34786 > 11.1.1.12.irdmi: Flags [.], ack 957, win 235, options [nop,nop,TS val 2424960083 ecr 3343949173], length 0
12:33:43.576629 IP 172.27.16.16.43908 > VM-0-11-centos.4789: VXLAN, flags [I] (0x08), vni 4097
IP 10.1.1.7.34786 > 11.1.1.12.irdmi: Flags [F.], seq 79, ack 957, win 235, options [nop,nop,TS val 2424960083 ecr 3343949173], length 0
12:33:43.576645 IP VM-0-11-centos.49343 > 172.27.16.16.4789: VXLAN, flags [I] (0x08), vni 4098
IP 11.1.1.12.irdmi > 10.1.1.7.34786: Flags [.], ack 80, win 219, options [nop,nop,TS val 3343949174 ecr 2424960083], length 0
```

可以看出协议的确是从udp端口`4789`传输的，使用VXLAN。

## 第三部分：服务发现和Ingress

### 1、服务发现

Docker支持自定义配置DNS服务发现，执行`docker run -it --name test1 --dns=8.8.8.8 --dns-search=dockercerts.com alpine sh`，输出：

```
[root@VM-16-16-centos ~]# docker run -it --name test1 --dns=8.8.8.8 --dns-search=dockercerts.com centos:7 sh
sh-4.2# cat /etc/resolv.conf
search dockercerts.com
nameserver 8.8.8.8
```

可以看出配置dns，实际是修改`/etc/resolv.conf`配置。

### 2、Ingress

对于集群，Docker Swarm提供类似K8S的Ingress模式，在Swarm集群内的任何宿主机节点都可以访问对应的容器服务，执行样例`docker service create --name test --replicas 2 -p 5000:80 nginx`，可以分别在Swarm集群的主机中看到对应的端口5000，如下：

```
[root@VM-16-16-centos ~]# netstat -tunpl
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      1042/sshd
tcp        0      0 0.0.0.0:37721           0.0.0.0:*               LISTEN      2700/docker-proxy
tcp        0      0 0.0.0.0:8000            0.0.0.0:*               LISTEN      1397687/docker-prox
tcp6       0      0 :::5000                 :::*                    LISTEN      2380/dockerd
```

其底层是通过Sevice Mesh四层路由网络实现，原理和Docker本身端口映射类似，可以参考`iptables -nvL`端口查看，其中负载均衡的实现可以了解下图。

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202402292102997.jpeg)

## 参考

（1）[https://zhuanlan.zhihu.com/p/558785823](https://zhuanlan.zhihu.com/p/558785823)

（2）[https://www.cnblogs.com/oscar2960/p/16536891.html](https://link.zhihu.com/?target=https%3A//www.cnblogs.com/oscar2960/p/16536891.html)

（3）[https://www.jianshu.com/p/e3a87c76aab4?utm\_campaign=maleskine&utm\_content=note&utm\_medium=seo\_notes&utm\_source=recommendation](https://link.zhihu.com/?target=https%3A//www.jianshu.com/p/e3a87c76aab4%3Futm_campaign%3Dmaleskine%26utm_content%3Dnote%26utm_medium%3Dseo_notes%26utm_source%3Drecommendation)

**欢迎点赞分享，搜索关注【鹅厂架构师】公众号，一起探索更多业界领先产品技术。**