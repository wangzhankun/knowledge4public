---
{"dg-publish":true,"page-title":"技术手册-虚拟扩展本地局域网协议VXLAN - 星融元Asterfusion","url":"https://asterfusion.com/technical-manual-vxlan/","tags":["网络/vxlan"],"permalink":"/计算机网络/VXLAN - 星融元/","dgPassFrontmatter":true}
---

转载自：[原始链接](https://asterfusion.com/technical-manual-vxlan/)，如有侵权，联系删除。


VXLAN全称Virtual eXtensible Local Area Network即虚拟扩展局域网，是由IETF定义的NVO3（Network Virtualization over Layer 3）标准技术之一，是对传统VLAN协议的一种扩展。VXLAN的特点是将L2的以太帧封装到UDP报文（即L2 over L4）中，并在L3网络中传输。

## VXLAN的产生背景

数据中心规模的壮大，虚拟机数量的快速增长与虚拟机迁移业务的日趋频繁，给传统的“二层+三层”数据中心网络带来了新的挑战：

###  虚拟机规模受网络设备表项规格的限制

对于同网段主机的通信而言，报文通过查询MAC表进行二层转发。服务器虚拟化后，数据中心中VM的数量比原有的物理机发生了数量级的增长，伴随而来的便是虚拟机网卡MAC地址数量的空前增加。一般而言，接入侧二层设备的规格较小，MAC地址表项规模已经无法满足快速增长的VM数量。

### 传统网络的隔离能力有限

VLAN作为当前主流的网络隔离技术，在标准定义中只有12比特，也就是说可用的VLAN数量只有4096。对于公有云或其它大型虚拟化云计算服务这种动辄上万甚至更多租户的场景而言，VLAN的隔离能力显然已经力不从心。

### 虚拟机迁移范围受限

虚拟机迁移，顾名思义，就是将虚拟机从一个物理机迁移到另一个物理机，但是要求在迁移过程中业务不能中断。要做到这一点，需要保证虚拟机迁移前后，其IP地址、MAC地址等参数维持不变。这就决定了，虚拟机迁移必须发生在一个二层域中。而传统数据中心网络的二层域，将虚拟机迁移限制在了一个较小的局部范围内。值得一提的是，通过堆叠、SVF、TRILL等技术构建物理上的大二层网络，可以将虚拟机迁移的范围扩大。但是，构建物理上的大二层，难免需要对原来的网络做大的改动，并且物理大二层网络的范围依然会受到种种条件的限制。

VXLAN采用L2 over L4（MAC-in-UDP）的报文封装模式，将二层报文用三层协议进行封装，可实现二层网络在三层范围内进行扩展，同时满足数据中心大二层虚拟迁移和多租户的需求。

## VXLAN的发展历程

协议最早由VMware、Arisa网络、Cisco提出，后期加入华为、博科、Red Hat、Intel等公司支持，IETF于2012年8月发布第一个RFC Internet Draft版本，最新的标准是2014年8月RFC 7348。

## VXLAN的相关概念

-   NVO3（Network Virtualization Over Layer3 3层之上的网络虚拟化）

基于IP Overlay的虚拟局域网络技术统称为NVO3。

-   NVE(Network Virtrualization Edge网络虚拟边缘节点）

是实现网络虚拟化的功能实体，VM里的报文经过NVE封装后，NVE之间就可以在基于L3的网络基础上建立起L2虚拟网络。网络设备实体以及服务器实体上的VSwitch都可以作为NVE。

-   VTEP（VXLAN Tunnel Endpoints，VXLAN隧道端点）

VXLAN网络的边缘设备，是VXLAN隧道的起点和终点，VXLAN报文的相关处理均在这上面进行。VTEP既可以是一个独立的网络设备，也可以是虚拟机所在的服务器。

-   VNI（VXLAN Network Identifier，VXLAN 网络标识符）

VNI类似VLAN ID，用于区分VXLAN段，不同VXLAN段的虚拟机不能直接二层相互通信。一个VNI表示一个租户，即使多个终端用户属于同一个VNI，也表示一个租户。VNI由24比特组成，支持多达16M（(2^24-1)/1024^2）的租户。

-   VXLAN隧道

“隧道”是一个逻辑上的概念，它并不新鲜，比如大家熟悉的GRE。说白了就是将原始报文“变身”下，加以“包装”，好让它可以在承载网络（比如IP网络）上传输。从主机的角度看，就好像原始报文的起点和终点之间，有一条直通的链路一样。而这个看起来直通的链路，就是“隧道”。顾名思义，“VXLAN隧道”便是用来传输经过VXLAN封装的报文的，它是建立在两个VTEP之间的一条虚拟通道。

-   BD（bridge domain）,vxlan转发二层数据报文的广播域，是承载vxlan数据报文的实体。类似于传统网络中VLAN的概念，只不过在VXLAN网络中，它有另外一个名字BD。不同的VLAN是通过VLAN ID来进行区分的，那不同的BD是通过VNI来区分的。
-   VXLAN报文格式

![VXLAN报文格式](https://asterfusion.com/wp-content/uploads/2022/06/VXLAN-1.png)

图1： VXLAN报文格式

![VXLAN标准报文格式](https://asterfusion.com/wp-content/uploads/2022/06/VXLAN-2-1024x637.png)

图2：VXLAN标准报文格式

## VXLAN的工作原理

### VXLAN网络中的通信过程

结合如下示例简要说明VXLAN网络中的通信过程：

![VXLAN通信过程](https://asterfusion.com/wp-content/uploads/2022/06/VXLAN-3-1024x589.png)

图3：VXLAN通信过程

图3中 Host-A 和 Host-B 位于 VNI 10 的 VXLAN，通过 VTEP-1 和 VTEP-2 之间建立的 VXLAN 隧道通信。

数据传输过程如下：

-   Host-A 向 Host-B 发送数据时，Host-B 的 MAC 和 IP 作为数据包的目标 MAC 和 IP，Host-A 的 MAC 作为数据包的源 MAC 和 IP，然后通过 VTEP-1 将数据发送出去。
-   VTEP-1 从自己维护的映射表中找到 MAC-B 对应的 VTEP-2，然后执行 VXLAN 封装，加上 VXLAN 头，UDP 头，以及外层 IP 和 MAC 头。此时的外层 IP 头，目标地址为 VTEP-2 的 IP，源地址为 VTEP-1 的 IP。同时由于下一跳是 Router-1，所以外层 MAC 头中目标地址为 Router-1 的 MAC。
-   数据包从 VTEP-1 发送出去后，外部网络的路由器会依据外层 IP 头进行包路由，最后到达与 VTEP-2 连接的路由器 Router-2。
-   Router-2 将数据包发送给 VTEP-2。VTEP-2 负责解封数据包，依次去掉外层 MAC 头，外层 IP 头，UDP 头 和 VXLAN 头。
-   VTEP-2 依据目标 MAC 地址将数据包发送给 Host-B。

上面的流程我们看到 VTEP 是 VXLAN 的最核心组件，负责数据的封装和解封。

隧道也是建立在 VTEP 之间的，VTEP 负责数据的传送。

### VTEP节点工作机制

通过以上通信步骤的描述可以看到，VTEP节点在VXLAN网络通信中起到了至关重要的作用。在VXLAN网络通信中，VTEP节的职责主要有3项：

-   将虚拟网络通信的数据帧添加VXLAN头部和外部UDP和IP首部。
-   将封装好的数据包转发给正确的VTEP节点。
-   收到其他VTEP发来的VXLAN报文时，拆除外部IP、UDP以及VXLAN首部，然后将内部数据包交付给正确的终端。

对于功能2)的实现，即VXLAN数据包的转发过程。当VTEP节点收到一个VXLAN数据包时，需要根据内部以太网帧的目的MAC地址找到与拥有该目的地址的终端直接相连的VTEP地址，因此，这里需要一个目的MAC地址和VTEP节点IP地址的映射关系，VTEP节点利用一个转发表来存储此映射关系。转发表的格式为：<VNI, Inner Dst MAC,VTEP IP>，即给定VNI和目的MAC地址后映射到一个VTEP IP地址。

需要说明的是，映射VTEP节点IP地址时，之所以需要VNI的信息，是因为当存在多租户的情况下，各个租户将会独立组网，此时，多个租户设定的MAC地址有一定的概率会出现重叠，此时我们必须保证每个租户的网络都能独立地正常通信，因此，在为每个租户配置唯一的一个VNI的情况下，给定VNI和目的MAC地址，唯一确定一个VTEP地址。

下图4是一个样例，对于下图中的网络拓扑，分别给出了两个VTEP节点的转发表：

![VTEP节点工作过程](https://asterfusion.com/wp-content/uploads/2022/06/VXLAN-4-1024x682.png)

图4：VTEP节点工作过程

上图中给出了6个终端，分别属于2个租户，其中，终端T1、T2和T4属于租户1，分配VNI为1，终端T3、T5和T6属于租户2，分配VNI为2，两个VTEP节点的转发表已在图中给出。

每一个VTEP节点都必须拥有完整的转发表才可以正确地进行转发的功能，转发表的学习过程可以基于这样一种简单的策略：通过ARP报文学习，当收到终端发送的数据帧时，首先根据收到数据的端口判定数据发送方的VNI值，根据VNI和数据帧中的目的MAC查找对应的VTEP节点，如果查找成功，则转发，否则，在当前VXLAN网络中广播ARP请求报文，这样，连接目的MAC终端的VTEP节点就会发送ARP回答报文，这样就学习到了新的转发表项。

需要说明的是，在多租户的环境下，基于信息安全等因素，各个租户的流量必须实现隔离，因此在发送广播ARP请求报文时，不可以直接在多租户的环境中广播，必须保证只有当前VXLAN网络的终端可以收到广播报文，因此，和物理网络中的ARP广播请求的实现有所不同，这里需要通过IP组播机制来模拟广播。

因此，VTEP节点还需要保存对应于每个租户的VNI值的组播域，即对于每一个VNI值，存储包含当前VXLAN网络中终端的所有VTEP节点的IP，用于ARP广播时的组播操作。

###  VXLAN二层网关与三层网关

-   VXLAN二层网关：用于终端接入VXLAN网络，也可用于同一VXLAN网络的子网通信。
-   VXLAN三层网关：用于VXLAN网络中跨子网通信以及访问外部网络。

### VXLAN集中式网关与分布式网关

根据三层网关部署方式的不同，VXLAN三层网关又可以分为集中式网关和分布式网关。

-   VXLAN集中式网关

集中式网关是指将三层网关集中部署在一台设备上，如下图所示，所有跨子网的流量都经过这个三层网关转发，实现流量的集中管理。

**图****5****：![VXLAN集中式网关](https://asterfusion.com/wp-content/uploads/2022/06/VXLAN-5-1024x464.png)**

部署集中式网关的优点和缺点如下：

-   优点：对跨子网流量进行集中管理，网关的部署和管理比较简单。
-   缺点：转发路径不是最优：同一二层网关下跨子网的数据中心三层流量都需要经过集中三层网关绕行转发（如图中橙色虚线所示）。
-   ARP表项规格瓶颈：由于采用集中三层网关，通过三层网关转发的终端的ARP表项都需要在三层网关上生成，而三层网关上的ARP表项规格有限，这不利于数据中心网络的扩展。
-   VXLAN分布式网关

VXLAN分布式网关是指在典型的“Spine-Leaf”组网结构下，将Leaf节点作为VXLAN隧道端点VTEP，每个Leaf节点都可作为VXLAN三层网关（同时也是VXLAN二层网关），Spine节点不感知VXLAN隧道，只作为VXLAN报文的转发节点。如下图所示，Server1和Server2不在同一个网段，但是都连接到一个Leaf节点。Server1和Server2通信时，流量只需要在Leaf1节点进行转发，不再需要经过Spine节点。

部署分布式网关时：

-   Spine节点：关注于高速IP转发，强调的是设备的高速转发能力。
-   Leaf节点：作为VXLAN网络中的二层网关设备，与物理服务器或VM对接，用于解决终端租户接入VXLAN虚拟网络的问题。作为VXLAN网络中的三层网关设备，进行VXLAN报文封装/解封装，实现跨子网的终端租户通信，以及外部网络的访问。

![VXLAN分布式网关](https://asterfusion.com/wp-content/uploads/2022/06/VXLAN-6-1024x433.png)

图6：VXLAN分布式网关

VXLAN分布式网关具有如下特点：

同一个Leaf节点既可以做VXLAN二层网关，也可以做VXLAN三层网关，部署灵活。

Leaf节点只需要学习自身连接服务器的ARP表项，而不必像集中三层网关一样，需要学习所有服务器的ARP表项，解决了集中式三层网关带来的ARP表项瓶颈问题，网络规模扩展能力强。

## VXLAN在星融元交换机上的配置实例

下面实例中星融元的两台CX306交换机通过配置BGP EVPN来实现VXLAN网络的建立。

![CX306交换机通过配置BGP EVPN来实现VXLAN网络的建立](https://asterfusion.com/wp-content/uploads/2022/06/VXLAN-7.png)