---
{"dg-publish":true,"date":"2023-12-10","time":"09:52","progress":"进行中","tags":["OS/Linux","网络","驱动"],"permalink":"/计算机网络/Linux BSP实战课（网络篇）：数据包的发送过程-腾讯云开发者社区-腾讯云/","dgPassFrontmatter":true}
---

# Linux BSP实战课（网络篇）：数据包的发送过程-腾讯云开发者社区-腾讯云

本文将介绍在Linux系统中，以一个UDP包的接收过程作为示例，介绍数据包是如何一步一步从应用程序到网卡并最终发送出去的。

## **socket层**



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/DfE7bO3hvo7czpxEc0ScOjBgnEg.png)





* socket(...)：创建一个socket结构体，并初始化相应的操作函数，由于我们定义的是UDP的socket，所以里面存放的都是跟UDP相关的函数
* sendto(sock, ...)：应用层的程序（Application）调用该函数开始发送数据包，该函数数会调用后面的inet_sendmsg
* inet_sendmsg：该函数主要是检查当前socket有没有绑定源端口，如果没有的话，调用inet_autobind分配一个，然后调用UDP层的函数
* inet_autobind：该函数会调用socket上绑定的get_port函数获取一个可用的端口，由于该socket是UDP的socket，所以get_port函数会调到UDP代码里面的相应函数。

## **UDP层**



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/Cc82bLeUuoFIJvxiCxocBjbjnWc.png)



* udp_sendmsg：udp模块发送数据包的入口，该函数较长，在该函数中会先调用ip_route_output_flow获取路由信息（主要包括源IP和网卡），然后调用ip_make_skb构造skb结构体，最后将网卡的信息和该skb关联。
* ip_route_output_flow：该函数会根据路由表和目的IP，找到这个数据包应该从哪个设备发送出去，如果该socket没有绑定源IP，该函数还会根据路由表找到一个最合适的源IP给它。如果该socket已经绑定了源IP，但根据路由表，从这个源IP对应的网卡没法到达目的地址，则该包会被丢弃，于是数据发送失败，sendto函数将返回错误。该函数最后会将找到的设备和源IP塞进flowi4结构体并返回给udp_sendmsg
* ip_make_skb：该函数的功能是构造skb包，构造好的skb包里面已经分配了IP包头，并且初始化了部分信息（IP包头的源IP就在这里被设置进去），同时该函数会调用__ip_append_dat，如果需要分片的话，会在__ip_append_data函数中进行分片，同时还会在该函数中检查socket的send buffer是否已经用光，如果被用光的话，返回ENOBUFS
* udp_send_skb(skb, fl4) 主要是往skb里面填充UDP的包头，同时处理checksum，然后调用IP层的相应函数。

## **IP层**



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/YSNcbIUWmoD4nAxa5Y7cxNZSnzf.png)



* ip_send_skb：IP模块发送数据包的入口，该函数只是简单的调用一下后面的函数
* __ip_local_out_sk：设置IP报文头的长度和checksum，然后调用下面netfilter的钩子
* NF_INET_LOCAL_OUT：netfilter的钩子，可以通过iptables来配置怎么处理该数据包，如果该数据包没被丢弃，则继续往下走
* dst_output_sk：该函数根据skb里面的信息，调用相应的output函数，在我们UDP IPv4这种情况下，会调用ip_output
* ip_output：将上面udp_sendmsg得到的网卡信息写入skb，然后调用NF_INET_POST_ROUTING的钩子
* NF_INET_POST_ROUTING：在这里，用户有可能配置了SNAT，从而导致该skb的路由信息发生变化
* ip_finish_output：这里会判断经过了上一步后，路由信息是否发生变化，如果发生变化的话，需要重新调用dst_output_sk（重新调用这个函数时，可能就不会再走到ip_output，而是走到被netfilter指定的output函数里，这里有可能是xfrm4_transport_output），否则往下走
* ip_finish_output2：根据目的IP到路由表里面找到下一跳(nexthop)的地址，然后调用__ipv4_neigh_lookup_noref去arp表里面找下一跳的neigh信息，没找到的话会调用__neigh_create构造一个空的neigh结构体
* dst_neigh_output：在该函数中，如果上一步ip_finish_output2没得到neigh信息，那么将会走到函数neigh_resolve_output中，否则直接调用neigh_hh_output，在该函数中，会将neigh信息里面的mac地址填到skb中，然后调用dev_queue_xmit发送数据包
* neigh_resolve_output：该函数里面会发送arp请求，得到下一跳的mac地址，然后将mac地址填到skb中并调用dev_queue_xmit

## **netdevice子系统**



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/C63fb9uGIo6xqmx5ldYcw7tqnMe.png)



* dev_queue_xmit：netdevice子系统的入口函数，在该函数中，会先获取设备对应的qdisc，如果没有的话（如loopback或者IP tunnels），就直接调用dev_hard_start_xmit，否则数据包将经过Traffic Control模块进行处理
* Traffic Control：这里主要是进行一些过滤和优先级处理，在这里，如果队列满了的话，数据包会被丢掉，详情请参考文档，这步完成后也会走到dev_hard_start_xmit
* dev_hard_start_xmit：该函数中，首先是拷贝一份skb给“packet taps”，tcpdump就是从这里得到数据的，然后调用ndo_start_xmit。如果dev_hard_start_xmit返回错误的话（大部分情况可能是NETDEV_TX_BUSY），调用它的函数会把skb放到一个地方，然后抛出软中断NET_TX_SOFTIRQ，交给软中断处理程序net_tx_action稍后重试（如果是loopback或者IP tunnels的话，失败后不会有重试的逻辑）
* ndo_start_xmit：这是一个函数指针，会指向具体驱动发送数据的函数

## **Device Driver**

ndo_start_xmit会绑定到具体网卡驱动的相应函数，到这步之后，就归网卡驱动管了，不同的网卡驱动有不同的处理方式，这里不做详细介绍，其大概流程如下：

1. 将skb放入网卡自己的发送队列
1. 通知网卡发送数据包
1. 网卡发送完成后发送中断给CPU
1. 收到中断后进行skb的清理工作

在网卡驱动发送数据包过程中，会有一些地方需要和netdevice子系统打交道，比如网卡的队列满了，需要告诉上层不要再发了，等队列有空闲的时候，再通知上层接着发数据。

## **其它**

* SO_SNDBUF: 从上面的流程中可以看出来，对于UDP来说，没有一个对应send buffer存在，SO_SNDBUF只是一个限制，当这个socket分配的skb占用的内存超过这个值的时候，会返回ENOBUFS，所以说只要不出现ENOBUFS错误，把这个值调大没有意义。从sendto函数的帮助文件里面看到这样一句话：(Normally, this does not occur in Linux. Packets are just silently dropped when a device queue overflows.)。这里的device queue应该指的是Traffic Control里面的queue，说明在linux里面，默认的SO_SNDBUF值已经够queue用了，疑问的地方是，queue的长度和个数是可以配置的，如果配置太大的话，按道理应该有可能会出现ENOBUFS的情况。
* txqueuelen: 很多地方都说这个是控制qdisc里queue的长度的，但貌似只是部分类型的qdisc用了该配置，如linux默认的pfifo_fast。
* hardware RX: 一般网卡都有一个自己的ring queue，这个queue的大小可以通过ethtool来配置，当驱动收到发送请求时，一般是放到这个queue里面，然后通知网卡发送数据，当这个queue满的时候，会给上层调用返回NETDEV_TX_BUSY
* packet taps(AF_PACKET): 当第一次发送数据包和重试发送数据包时，都会经过这里。

本文参与 [腾讯云自媒体分享计划 ](https://cloud.tencent.com/developer/support-plan)，分享自微信公众号。

推荐

[Linux BSP实战课（网络篇）：数据包的接收过程](https://cloud.tencent.com/developer/article/2331479?areaId=106001)

本文将介绍在Linux系统中，以一个UDP包的接收过程作为示例，介绍数据包是如何一步一步从网卡传到进程手中的。



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/BfMBbZTT6oL98kxaqGmclBt1nud.jpeg)



[探索eBPF：Linux内核的黑科技](https://cloud.tencent.com/developer/article/2298640?areaId=106001)

Linux内核在2022年主要发布了5.16-5.19以及6.0和6.1这几个版本，每个版本都为eBPF引入了大量的新特性。本文将对这些新特性进行一点简要的介绍，更详细的资料请参考对应的链接信息。总体而言，eBPF在内核中依然是最活跃的模块之一，它的功能特性也还在高速发展中。某种意义上说，eBPF正朝着一个完备的内核态可编程接口快速进化。



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/Jvs7bBWoQo28hzx5N2ZcCn23nrc.png)



[在云原生场景中，nettrace 如何快速进行网络故障诊断](https://cloud.tencent.com/developer/article/2231925?areaId=106001)

在一些场景下（特别是云原生场景），Linux 系统中的网络部署变得越来越复杂。一个 TCP 连接，从客户端到服务端，中间可能要经过复杂的 NAT、GRE、IPVS 等过程，网络报文在节点（主机）上的处理路径也变得越来越长。在发生网络故障（比如网络丢包）时，如何快速、有效地定位出网络问题成为了一个难题。目前常规的网络故障定位手段，如 tcpdump、dropwatch、ftrace、kprobe 等存在一定的短板：

[Linux 网络设备驱动开发（一） —— linux内核网络分层结构](https://cloud.tencent.com/developer/article/2154372?areaId=106001)

Linux内核对网络驱动程序使用统一的接口，并且对于网络设备采用面向对象的思想设计。



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/Yzsdb20DMohHaWxXYvjcTo1InVf.png)



[Linux驱动之网卡驱动剖析](https://cloud.tencent.com/developer/article/2164607?areaId=106001)

网络设备不同于字符设备和块设备，并不对应于/dev目录下的文件，应用程序通过 socket 完成与网络设备的交互，在网络设备上并不体现”一切皆文件”的设计思想。



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/D87Fbg54ko6LYDxZOb0cTqPInFe.png)



[云原生场景下，nettrace怎么快速进行网络故障诊断？](https://cloud.tencent.com/developer/article/2208215?areaId=106001)

导言｜nettrace工具自上线以来，受到了业界的广泛关注。特别是复杂的云原生网络环境中，nettrace 工具通过报文跟踪、网络诊断的方式为用户解决了多次疑难网络问题。今天就以OpenCloudOS为例，介绍在云原生场景中nettrace如何快速进行网络故障诊断。 工具简介 1）背景 在一些场景下（特别是云原生场景），Linux 系统中的网络部署变得越来越复杂。一个 TCP 连接，从客户端到服务端，中间可能要经过复杂的 NAT、GRE、IPVS 等过程，网络报文在节点（主机）上的处理路径也变得越来越长



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/HiZIbVWAtoAshlxr0JacH2van4e.jpeg)



[jvm可达性分析算法_对点网络](https://cloud.tencent.com/developer/article/2164203?areaId=106001)

IP层叫分片，TCP/UDP层叫分段。网卡能做的事（TCP/UDP组包校验和分段，IP添加包头校验与分片）尽量往网卡做，网卡不能做的也尽量迟后分片（发送）或提前合并片（接收）来减少在网络栈中传输和处理的包数目，从而减少数据传输和上下文切换所需要的CPU计算时间。



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/Awmfbc8PAoxdkUxAzYcc9hmcn8b.jpeg)



[如何做到每秒接收100万个数据包](https://cloud.tencent.com/developer/article/2241653?areaId=106001)

上周在一次偶然的谈话中，我无意中听到一位同事说:Linux的网络堆栈太慢了!你不能指望它在每个核每秒处理超过5万个数据包!



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/QECjb5t7koItegxbdiqcFLzKnuL.jpeg)



[[勘误篇] 图解eBPF socket level 重定向的内核实现细节](https://cloud.tencent.com/developer/article/2245006?areaId=106001)

大家好，我是二哥。最近一直在研究 eBPF ，随着研究的深入，我发现之前写的这篇文章有点问题，所以重新修改了一下。图也重新画了，并添加了一些与 sidecar-less 相关的额外内容。



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/Gy9ebKvciovkEBxfD3XcDjhHnhe.jpeg)



[利用eBPF实现socket level重定向](https://cloud.tencent.com/developer/article/2212368?areaId=106001)

最近二哥利用业余时间在复习 eBPF ，为啥说是复习呢？因为我曾经短暂使用过 eBPF 。一晃几年过去了，我在研究 K8s 网络模型和 service mesh 的过程中，反复看到它的出现。它真是一个勤劳的小蜜蜂，哪里都能看到它的身影。而我在几年后重新拾起 eBPF ，对它有了更深的感悟，对它的小巧精悍也有了更多的喜爱。

[前驱知识——Linux网络虚拟化](https://cloud.tencent.com/developer/article/2262074?areaId=106001)

信息是如何通过网络传输被另一个程序接收到的？我们讨论的虚拟化网络是狭义的，它指容器间网络。



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/QpBBbIw6JoEBP5xKG2AcLy2Unvc.jpeg)



[DPDK 网卡收包流程](https://cloud.tencent.com/developer/article/2235365?areaId=106001)

NIC 在接收到数据包之后，首先需要将数据同步到内核中，这中间的桥梁是 rx ring buffer。它是由 NIC 和驱动程序共享的一片区域，事实上，rx ring buffer 存储的并不是实际的 packet 数据，而是一个描述符，这个描述符指向了它真正的存储地址，具体流程如下：



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/NPFjbkqBNoaueSxUFSRctgyjn4c.jpeg)



[OpenCloudOS 如何利用 nettrace 进行网络故障诊断](https://cloud.tencent.com/developer/article/2210423?areaId=106001)

在开源 Linux 操作系统 OpenCloudOS 8.6 中，增加了内核对网络工具 nettrace 的支持，允许开发者通过 bpf 进行网络丢包原因跟踪，内核也同时回合相关的丢包跟踪点。今天，就以 nettrace 为典型，介绍如何在 OpenCloudOS 中利用 nettrace 进行网络故障诊断。 一、工具简介 1. 背景 在一些场景下（特别是云原生场景），Linux 系统中的网络部署变得越来越复杂。一个 TCP 连接，从客户端到服务端，中间可能要经过复杂的 NAT、GRE、IPVS 等过程，网



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/VzmGb4Y64oJXclxLcp7csoD8nIf.png)



[支撑 100Gbit/s K8s 集群的未来网络数据平面](https://cloud.tencent.com/developer/article/2241813?areaId=106001)

BIG TCP 并不是一个适应于大部分场景的通用方案，而是针对数据密集型应用的优化，在这些场景下能显著提升网络性能。



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/GMftbWCgfoeRrxxsyvtcQTWJnzc.jpeg)



[理解 net device Ingress 和 Egress 双重角色](https://cloud.tencent.com/developer/article/2236670?areaId=106001)

本文是书稿《图解 VPC & K8s 网络模型》其中一篇。书稿还在继续写，进度不快也不慢，因为二哥不急也不躁。好肉需要慢炖，好书需要多磨。



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/QQpBbutuMowl2ax85HOc7ECSnug.jpeg)



[这个点，在面试中答出来很加分！](https://cloud.tencent.com/developer/article/2248716?areaId=106001)

最近在带大家做新项目，欢迎参与 大家好，我是鱼皮。今天和大家聊一个有点儿东西的面试题：socket是否是并发安全的？ 为了帮助大家理解，我们先假设一个场景。 就拿游戏架构来说，我们想象中的游戏架构是下面这样的。 想象中的游戏架构 也就是用户客户端直接连接游戏核心逻辑服务器，下面简称GameServer。GameServer主要负责实现各种玩法逻辑。 这当然是能跑起来，实现也很简单。 但这样会有个问题，因为游戏这块蛋糕很大，所以总会遇到很多挺刑的事情。 如果让用户直连GameServer，那相当于把Game



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/EhKjbbgyQolWpCxexWjcLSQPnVb.jpeg)



[如何学习 Linux 内核网络协议栈](https://cloud.tencent.com/developer/article/2161266?areaId=106001)

sk_buff 是一个贯穿整个协议栈层次的结构，在各层间传递时，内核只需要调整 sk_buff 中的指针位置就行。



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/QvU2b5uJpoi7NqxqHJKc0BrZngg.png)



[图解eBPF socket level 重定向的内核实现细节](https://cloud.tencent.com/developer/article/2218848?areaId=106001)

上一篇《利用eBPF实现socket level重定向》，二哥从整体上介绍了 eBPF 的一个应用场景 socket level redirect：如果一台机器上有两个进程需要通过 loopback 设备相互收发数据，我们可以利用 ebpf 在发送进程端将需要发送的数据跳过本机的底层 TCP/IP 协议栈，直接交给目的进程的 socket，从而缩短数据在内核的处理路径和时间。



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/XYTkbpMbFo6JE3xzr7xcZrfNnQd.jpeg)



[如何学习 Linux 内核网络协议栈](https://cloud.tencent.com/developer/article/2168404?areaId=106001)

内核显然需要一个数据结构来表示报文，这个结构就是 sk_buff ( socket buffer 的简称)，它等同于在<TCP/IP详解 卷2>中描述的 BSD 内核中的 mbuf。



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/BUYWbeyfkoCrEkxA6xsch1FVnfe.png)



[eBPF 技术实践：加速容器网络转发，耗时降低60%+](https://cloud.tencent.com/developer/article/2177278?areaId=106001)

Linux 具有功能丰富的网络协议栈，并且兼顾了非常优秀的性能。但是，这是相对的。单纯从网络协议栈各个子系统的角度来说，确实做到了功能与性能的平衡。不过，当把多个子系统组合起来，去满足实际的业务需求，功能与性能的天平就会倾斜。



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/TCYVbyzGbomtvRxONsIcSWssngd.jpeg)



 相关推荐

Linux BSP实战课（网络篇）：数据包的接收过程

更多 >

