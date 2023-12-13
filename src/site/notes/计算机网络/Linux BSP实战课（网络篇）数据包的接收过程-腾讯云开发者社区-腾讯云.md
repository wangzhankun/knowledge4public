---
{"dg-publish":true,"date":"2023-12-10","time":"09:53","progress":"进行中","tags":["OS/Linux","网络"],"permalink":"/计算机网络/Linux BSP实战课（网络篇）数据包的接收过程-腾讯云开发者社区-腾讯云/","dgPassFrontmatter":true}
---

# Linux BSP实战课（网络篇）：数据包的接收过程-腾讯云开发者社区-腾讯云

本文将介绍在Linux系

统中，以一个UDP包的接收过程作为示例，介绍数据包是如何一步一步从网卡传到进程手中的。

## **网卡到内存**

网络接口卡必须安装与之匹配的驱动程序才能正常工作。这些驱动程序被视为内核模块，其主要职责是连接网卡和内核中的网络模块。在加载驱动程序时，驱动程序将自身注册到网络模块中。当相应的网卡接收到数据包时，网络模块将调用相应的驱动程序来处理数据。

下图展示了数据包（packet）如何进入内存，并被内核的网络模块开始处理：



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/DJnmbQlIDo9T3cxfoHlcD1wfnAe.png)



* 1：外部网络传入的数据包会进入物理网卡。当目的地址不属于该网卡，且该网卡未启用混杂模式时，该数据包将被网卡丢弃。
* 2：网卡使用直接内存访问（DMA）技术将数据包写入指定的内存地址。这些内存地址由网卡驱动程序进行分配和初始化。
* 3：网卡通过硬件中断请求（IRQ）向CPU发送通知，以告知数据已到达。
* 4：CPU根据中断表的配置，调用已注册的中断处理函数，该函数会进一步调用网卡驱动程序（网络接口卡驱动程序）中相应的函数。
* 5：驱动程序首先禁用网卡的中断功能，表示驱动程序已知晓数据已存储在内存中，并告知网卡在接收到下一个数据包时直接写入内存，而无需再次通知CPU，从而提高效率，并避免CPU被频繁中断。
* 6：启动软中断。硬中断处理函数执行期间不可被中断，若其执行时间过长，则会导致CPU无法响应其他硬件的中断。因此，内核引入软中断的概念，将硬中断处理函数中耗时的部分转移到软中断处理函数中，以便逐步处理。

## **内核的网络模块**

软中断会触发内核网络模块中的软中断处理函数，后续流程如下:



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/JxjwbFrAMo2zwYx3wGzcM1x6nPe.png)



* 7：在操作系统内核中，存在一个专门处理软中断的进程，称为ksoftirqd。当ksoftirqd接收到软中断时，它会调用相应的软中断处理函数，对于上述提到的第6步中由网卡驱动模块触发的软中断，ksoftirqd会调用网络模块中的net_rx_action函数。
* 8：net_rx_action函数会调用网卡驱动中的poll函数，逐个处理数据包。
* 9：在poll函数中，驱动程序会逐个读取网卡写入内存的数据包，该数据包的格式只有驱动程序知道。
* 10：驱动程序将内存中的数据包转换为内核网络模块可识别的skb格式，并调用napi_gro_receive函数。
* 11：napi_gro_receive函数会处理与GRO（通用接收处理）相关的内容，即将可合并的数据包进行合并，从而只需调用一次协议栈。然后检查是否启用了RPS（接收包分发），若启用，则调用enqueue_to_backlog函数。
* 12：在enqueue_to_backlog函数中，数据包将被放入CPU的softnet_data结构体的input_pkt_queue队列中，然后返回。如果input_pkt_queue队列已满，则会丢弃该数据包，该队列的大小可以通过net.core.netdev_max_backlog参数进行配置。
* 13：CPU会在自身的软中断上下文中处理input_pkt_queue队列中的网络数据（调用__netif_receive_skb_core函数）。
* 14：如果未启用RPS，napi_gro_receive函数会直接调用__netif_receive_skb_core函数。
* 15：首先检查是否存在AF_PACKET类型的套接字（即原始套接字），如果存在，则将数据包复制给该套接字。例如，tcpdump抓取的数据包即是在此处捕获的。
* 16：调用相应的协议栈函数，将数据包交给协议栈处理。
* 17：在内存中的所有数据包处理完成后（即poll函数执行完成），启用网卡的硬中断，这样当网卡接收到下一批数据时，将会通知CPU。

## **协议栈**

### **IP层**

由于是UDP包，所以第一步会进入IP层，然后一级一级的函数往下调：



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/HCypbRiSfoFRYoxcePxcXvIQnXe.png)



* ip_rcv：ip_rcv函数是IP模块的入口函数，在该函数里面，第一件事就是将垃圾数据包（目的mac地址不是当前网卡，但由于网卡设置了混杂模式而被接收进来）直接丢掉，然后调用注册在NF_INET_PRE_ROUTING上的函数
* NF_INET_PRE_ROUTING：netfilter放在协议栈中的钩子，可以通过iptables来注入一些数据包处理函数，用来修改或者丢弃数据包，如果数据包没被丢弃，将继续往下走
* routing：进行路由，如果目的IP不是本地IP，且没有开启ip forward功能，那么数据包将被丢弃，如果开启了ip forward功能，那将进入ip_forward函数
* ip_forward：ip_forward会先调用netfilter注册的NF_INET_FORWARD相关函数，如果数据包没有被丢弃，那么将继续往后调用dst_output_sk函数
* dst_output_sk：该函数会调用IP层的相应函数将该数据包发送出去。
* ip_local_deliver：如果上面routing的时候发现目的IP是本地IP，那么将会调用该函数，在该函数中，会先调用NF_INET_LOCAL_IN相关的钩子程序，如果通过，数据包将会向下发送到UDP层

### **UDP层**



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/JqAhbku3Yopr3NxdaY8cj2w8nOf.png)



* udp_rcv函数是UDP模块的入口函数，用于处理接收到的UDP数据包。在该函数中会进行一系列检查，并调用其他函数进行处理。其中，一个重要的函数调用是__udp4_lib_lookup_skb，该函数根据目标IP和端口查找对应的socket。如果找不到相应的socket，则该数据包将被丢弃；否则，继续处理。
* sock_queue_rcv_skb函数的主要功能是进行两项检查。首先，它会检查socket的接收缓冲区是否已满，如果已满，则会丢弃该数据包。然后，它会调用sk_filter函数检查该包是否满足当前socket设置的过滤条件。如果socket上设置了过滤条件且该数据包不满足条件，则该数据包也会被丢弃。在Linux中，每个socket都可以像tcpdump中一样定义过滤条件，不满足条件的数据包将被丢弃。
* __skb_queue_tail函数用于将数据包放入socket的接收队列末尾。
* sk_data_ready函数用于通知socket数据包已准备就绪，可以进行处理。

## **socket**

应用层一般有两种方式接收数据，一种是recvfrom函数阻塞在那里等着数据来，这种情况下当socket收到通知后，recvfrom就会被唤醒，然后读取接收队列的数据；另一种是通过epoll或者select监听相应的socket，当收到通知后，再调用recvfrom函数去读取接收队列的数据。两种情况都能正常的接收到相应的数据包。

## **结束语**

了解数据包的接收流程有助于帮助我们搞清楚我们可以在哪些地方监控和修改数据包，哪些情况下数据包可能被丢弃，为我们处理网络问题提供了一些参考，同时了解netfilter中相应钩子的位置，对于了解iptables的用法有一定的帮助。

本文参与 [腾讯云自媒体分享计划 ](https://cloud.tencent.com/developer/support-plan)，分享自微信公众号。

