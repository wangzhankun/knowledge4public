---
{"dg-publish":true,"date":"2023-12-09","time":"21:43","progress":"进行中","tags":["用户态驱动","驱动"],"permalink":"/体系结构与操作系统/驱动/虚拟化 vfio 和UIO 区别 - 知乎/","dgPassFrontmatter":true}
---

# 虚拟化 vfio 和UIO 区别 - 知乎

## UIO -->IOMMU --> VFIO

1、UIO的出现，允许将驱动程序用到用户态空间里实现，但UIO有它的不足之处，如不支持DMA、中断等；

2、随着虚拟化的出现，IOMMU也随之出现，IOMMU为每个直通的设备分配独立的页表，因此不同的直通设备(passthrough)，彼此之间相互隔离；

3、有一些场景，多个PCI设备之间是有相互联系的，他们互相组成一个功能实体，彼此之间是可以相互访问的，因此IOMMU针对这些设备是行不通的，随之出现VFIO技术，VFIO兼顾了UIO和IOMMU的优点，在VFIO里，直通的最小单元不再是某个单独的设备了，而是分布在同一个group的所有设备；VFIO可以安全地把设备IO、中断、DMA等暴露到用户空间。



4、kvm的PCI、PCIE设备直通，默认都是通过VFIO实现的（通过virsh attach-device xxx会自动插vfio的相关ko，自动生成vfio的container）；

5、PCIE与PCI直通的区别是：PCI只能直通给某个特定的虚拟机，而PCIE有可能可以给多个虚拟机用，如具有SR-IOV功能的PCIE设备，通过在HOST上抽象出多个的VF，每个VF再通过VFIO直通给虚拟机，最终的表现就是一个物理PCIE网卡可以直通给多个虚拟机用；

6、SR-IOV是针对PCIE设备的，PCI设备理论上不具有SR-IOV功能；

## UIO

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/AQwAboue7oN4QXxnT9QcnE6HnQh.png)

UIO 框架导出sysfs和/dev/uioX 2套用户态接口，用户对设备节点/dev/uioX进行设备控制，mmap()接口用于映射设备寄存器空间，write()接口用于控制中断关闭/打开，read()接口用于等待一个设备中断。

因为对于设备中断的应答必须在内核空间进行，所以在内核空间有一小部分代码用来应答中断和禁止中断，其余的工作全部留给用户空间处理。如果用户空间要等待一个设备中断，它只需要简单的阻塞在对 /dev/uioX的read()操作上。 当设备产生中断时，read()操作立即返回。UIO 也实现了poll()系统调用，你可以使用 select()来等待中断的发生。select()有一个超时参数可以用来实现有限时间内等待中断。

UIO的几个特点：

* 一个UIO设备最多支持5个mem和portio空间mmap映射。
* UIO设备的中断用户态通信机制基于wait_queue实现。
* 一个UIO设备只支持一个中断号注册，支持中断共享。

总的来说，UIO框架适用于简单设备的驱动，因为它不支持DMA，不能支持多个中断线，缺乏逻辑设备抽象能力。

## IOMMU

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/ALjxbc3z4oNv2ZxlymZcN4H1nCb.png)

我说的IOMMU是指位于北桥上的IOMMU,那种设备自带IOMMU的情况我还不了解。

在没有IOMMU的情况下，设备（指32bit或64bit设备，老的16bit的不提）的DMA操作可以访问整个物理地址空间，所以理论上设备可以向操作系统的代码段、数据段等内存区域做DMA，从而破坏整个系统。当然，通常来说不会有这样的设备。IOMMU的出现，可以实现地址空间上的隔离，使设备只能访问规定的内存区域。下面简要说一下intel的IOMMU怎么做到这点的：

目前PC架构最多有256PCI总线，于是IOMMU用一个称为root entry的数据结构描述PCI总线，总共256个root entry构成一张表。每条PCI总线最多允许256个设备，IOMMU用context entry描述一个PCI设备（或者是PCI桥），256个context entry构成一张表。所以就有了如图的关系。我们知道，PCI设备用 {BUSEV:FUNC}（当然，还有个segment，不过似乎PC架构都只有一个segment，这个暂时忽略）描述一个设备。所以对于一个特定设备，用bus号做索引root entry表，用dev号索引context entry表可以找到描述该设备的的context entry。context entry中有一个指针指向一章I/O页表，当设备发起DMA操作时，IOMMU会根据该页表把设备的DMA地址转换成该设备可以访问内存区域的地址。

所以只要为设备建一张I/O页表，就可以使设备只能访问规定的内存区域了。当然，也可以把该页表当成跳板，让只能寻址32bit地址空间的设备访问到64bit地址空间中去。

Many platforms contain an extra piece of hardware called an I/O Memory Management Unit (IOMMU). An IOMMU is much like a regular MMU, exceptit provides virtualized address spaces to peripheral devices (i.e. on the PCI bus).TheMMU knows about virtual to physical mappings per process on the system, so the IOMMU associates a particular device with one of these mappings and then allows the user to assign arbitrary *bus addresses*to virtual addresses in their process.All DMA operations between the PCI device and system memory are then translated through the IOMMU by converting the bus address to a virtual address and then the virtual address to the physical address. This allows the operating system to freely modify the virtual to physical address mapping without breaking ongoing DMA operations. Linux provides a device driver, `vfio-pci` , that allows a user to configure the IOMMU with their current process.

大概就是这么回事了，似乎写的有点乱，具体问题看spec。

## VFIO

vfio使用参考kernel/Documentation/vfio.txt

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/IR6SbVWthoq4a1xAgllcCRQ8nte.jpeg)

上文提到，UIO不支持DMA，所以通过DMA传输大流量数据的IO设备，如网卡、显卡等设备，无法使用UIO框架，VFIO做为UIO的升级版，主要就是解决了这个问题。通过用户态配置IOMMU接口，可以将DMA地址空间映射限制在进程虚拟空间中。这对高性能驱动和虚拟化场景device passthrough尤其重要。

在VFIO框架中，有几个核心概念或对象：IOMMU、/dev/vfio、container、iommu_group。

* IOMMU是一个硬件单元，它可以把设备的IO地址映射成虚拟地址，为设备提供页表映射，设备通过IOMMU将数据直接DMA写到用户空间。之所以不共用MMU单元，是为了保证和进程的页表相互独立，防止设备访问进程的任意地址空间。所以VFIO的IOMMU功能保障了安全的非特权级别的用户态设备驱动机制。
* /dev/vfio是一个设备文件，作为一个IOMMU设备的用户态呈现。
* container是内核对象，表示一个IOMMU设备，是一个IOMMU设备的内核态呈现。所以在VFIO中，container是IOMMU操作的最小对象（container中有多个iommu_group）。
* 在虚拟化场景下，一个物理网卡可能要虚拟成几个虚拟网卡，或者说虚拟功能设备（VF），这几个VF共用一个IOMMU，所以VFIO模型增加一个iommu_group的概念，用来表示共享同一个IOMMU的一组device。

**VFIO的几个特点**：

* VFIO设备支持多中断号注册。
* 设备的中断用户态通信机制基于eventfd/irqfd实现。用户通过/dev/vfio设备select/poll/epoll，从而实现中断从内核态到用户态的异步事件通知。
* 支持对物理设备进行逻辑抽象。
* 仅支持pci intx中断共享，其他类型中断不支持共享。
* VFIO仅支持特定IOMMU设备，如x86与PowerPC平台的PCI设备和ARM平台的platform设备。

### **概述**

VFIO是一套用户态驱动框架，它提供两种基本服务：

* 向用户态提供访问硬件设备的接口
* 向用户态提供配置IOMMU的接口

VFIO由平台无关的接口层与平台相关的实现层组成。接口层将服务抽象为IOCTL命令，规化操作流程，定义通用数据结构，与用户态交互。实现层完成承诺的服务。据此，可在用户态实现支持DMA操作的高性能驱动。在虚拟化场景中，亦可借此完全在用户态实现device passthrough。

VFIO实现层又分为设备实现层与IOMMU实现层。当前VFIO仅支持PCI设备。IOMMU实现层则有x86与PowerPC两种。VFIO设计灵活，可以很方便地加入对其它种类硬件及IOMMU的支持。

### **接口**

与KVM一样，用户态通过IOCTL与VFIO交互。可作为操作对象的几种文件描述符有：

* Container文件描述符



* IOMMU group文件描述符



* Device文件描述符



逻辑上来说，IOMMU group是IOMMU操作的最小对象。某些IOMMU硬件支持将若干IOMMU group组成更大的单元。VFIO据此做出container的概念，可容纳多个IOMMU group。打开/dev/vfio文件即新建一个空的container。在VFIO中，container是IOMMU操作的最小对象。

要使用VFIO，需先将设备与原驱动拨离，并与VFIO绑定。

**用VFIO访问硬件的步骤：**

* 打开设备所在IOMMU group在/dev/vfio/目录下的文件
* 使用VFIO_GROUP_GET_DEVICE_FD得到表示设备的文件描述 (参数为设备名称，一个典型的PCI设备名形如0000:03.00.01)
* 对设备进行read/write/mmap等操作

**用VFIO配置IOMMU的步骤：**

* 打开/dev/vfio，得到container文件描述符
* 用VFIO_SET_IOMMU绑定一种IOMMU实现层
* 打开/dev/vfio/N，得到IOMMU group文件描述符
* 用VFIO_GROUP_SET_CONTAINER将IOMMU group加入container
* 用VFIO_IOMMU_MAP_DMA将此IOMMU group的DMA地址映射至进程虚拟地址空间

### **逻辑**

VFIO设备实现层与Linux设备模型紧密相连，当前，VFIO中仅有针对PCI的设备实现层(实现在vfio-pci模块中)。设备实现层的作用与普通设备驱动的作用类似。普通设备驱动向上穿过若干抽象层，最终以Linux里广为人知的抽象设备(网络设备，块设备等等)展现于世。VFIO设备实现层在/dev/vfio/目录下为设备所在IOMMU group生成相关文件，继而将设备暴露出来。两者起点相同，最终呈现给用户态不同的接口。欲使设备置于VFIO管辖之下，需将其与旧驱动解除绑定，由VFIO设备实现层接管。用户态能感知到的，是一个设备的消失(如eth0)，及/dev/vfio/N文件的诞生(其中N为设备所在IOMMU group的序号)。由于IOMMU group内的设备相互影响，只有组内全部设备被VFIO管理时，方能经VFIO配置此IOMMU group。

把设备归于IOMMU group的策略由平台决定。在PowerNV平台，一个IOMMU group与一个PE对应。PowerPC平台不支持将多个IOMMU group作为更大的IOMMU操作单元，故而container只是IOMMU group的简单包装而已。对container进行的IOMMU操作最终会被路由至底层的IOMMU实现层，这实际上将用户态与内核里的IOMMU驱动接连了起来。

### **总结**

VFIO是一套用户态驱动框架，可用于编写高效用户态驱动；在虚拟化情景下，亦可用来在用户态实现device passthrough。通过VFIO访问硬件并无新意，VFIO可贵之处在于第一次向用户态开放了IOMMU接口，能完全在用户态配置IOMMU，将DMA地址空间映射进而限制在进程虚拟地址空间之内。这对高性能用户态驱动以及在用户态实现device passthrough意义重大。


### **VFIO**

VFIO是一个可以安全的把设备I/O、中断、DMA等暴露到用户空间（userspace），从而可以在用户空间完成设备驱动的框架。用户空间直接设备访问，虚拟机设备分配可以获得更高的IO性能。

### **IOMMU**

实现用户空间设备驱动，最困难的在于如何将DMA以安全可控的方式暴露到用户空间：
- 提供DMA的设备通常可以写内存的任意页，因此使用户空间拥有创建DMA的能力就等同于用户空间拥有了root权限，恶意的设备可能利用此发动DMA攻击。
- I/O memory management unit(IOMMU)的引入对设备进行了限制，设备I/O地址需要经过IOMMU重映射为内存物理地址。恶意的或存在错误的设备不能读写没有被明确映射过的内存，运行在cpu上的操作系统以互斥的方式管理MMU与IOMMU，物理设备不能绕行或污染可配置的内存管理表项。

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/SyOdbT90doNE34xSXl5cIL9DnDc.jpeg)

IOMMU的其他好处：
- IOMMU可以将连续的虚拟地址映射到不连续的多个物理内存片段，从而支持vectored I/O（scatter-gather list）；
- 对于不能寻址全部物理地址空间的设备，通过IOMMU的重映射，从而避免了将数据从设备可访问的外围地址空间拷入拷出设备无法访址的物理地址空间的额外开销(避免了bounce buffer)。

## **实现**

VFIO由平台无关的接口层与平台相关的实现层组成。接口层将服务抽象为IOCTL命令，规化操作流程，定义通用数据结构，与用户态交互。实现层完成承诺的服务。据此，可在用户态实现支持DMA操作的高性能驱动。在虚拟化场景中，亦可借此完全在用户态实现device passthrough。





**本文转载自：****[https://www. cnblogs.com/yi-mu-xi/p/ 10515609.html ](https://link.zhihu.com/?target=https%3A//www.cnblogs.com/yi-mu-xi/p/10515609.html)**

## **DPDK 学习**

[  ](https://link.zhihu.com/?target=https%3A//www.bilibili.com/video/BV1Ju411z773%3Fspm_id_from%3D333.337.search-card.all.click%26vd_source%3Df7f486a36ebdfd9581527778cc782a98)

**Dpdk 系统性学习课程：**[https:// ke.qq.com/course/506620 3?flowToken=1043068 ](https://link.zhihu.com/?target=https%3A//ke.qq.com/course/5066203%3FflowToken%3D1043068)

DPDK开发学习资料、教学视频和学习路线图分享有需要的可以自行添加学习交流 **[群973961276 ](https://link.zhihu.com/?target=https%3A//jq.qq.com/%3F_wv%3D1027%26k%3DMrdUVba7)**获取

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/GR9mbImy2oucaTxl4zzcBOownOd.jpeg)



发布于 2022-07-20 17:41

