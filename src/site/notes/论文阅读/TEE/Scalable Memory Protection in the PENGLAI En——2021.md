---
{"dg-publish":true,"permalink":"/论文阅读/TEE/Scalable Memory Protection in the PENGLAI En——2021/","dgPassFrontmatter":true}
---


# Scalable Memory Protection in the PENGLAI En——2021

# **摘要**

在本文中，我们提出了一种软硬件协同设计，以支持动态、细粒度、大规模安全存储以及快速初始化。我们首先介绍了两个新的硬件原语：1)保护页表(guarded page table, GPT)，它保护页表页面以支持页级安全存储隔离；2)可装载Merkle树(mountable merkele tree, MMT, [[数据结构/Merkle Tree（默克尔树）算法解析-阿里云开发者社区\|Merkle Tree（默克尔树）算法解析-阿里云开发者社区]])，它支持可扩展的安全存储完整性保护。在这两个原语的基础上，我们的系统可以扩展到数千个并发飞地，具有高资源利用率，并且在不削弱安全保证的情况下，使用fork-enclave创建安全内存的方法消除了高成本的enclave初始化。

# **论文研究目标**

## **问题**

1. Non-scalable memory partition/isolation
1. Non-scalable memory integrity protection
1. Non-scalable secure memory initialization

## 贡献

我们扩展了安全监视器，通过两个硬件原语支持可扩展的安全内存保护，以及快速创建Enclave。在启动延迟方面，蓬莱利用影子Enclave将Enclave的创建速度提高了三个数量级(具有16MB Enclave内存)。

# **方法**

## Overview

![](https://cdn.jsdelivr.net/gh/wangzhankun/img-repo/boxcnyrqgw17hIC1gwpuH1Uhcxc.png)

安全监视器管理所有飞地，并为用户部署飞地提供API。此外，为了最小化安全监视器的大小，我们将资源保护与管理[51]分开：安全监视器仅配置特权硬件资源(例如，GPT和MMT配置)，而其他硬件的管理由不可信的主机操作系统完成。

在系统引导期间，安全监视器由boot ROM加载和验证，即安全引导。然后，它控制系统并通过硬件支持的内存隔离(例如，RISC-V PMP)进行自我保护。它还利用加密和可装载的Merkle树来保护自己免受物理内存攻击。

保护页表(GPT)是细粒度内存隔离的基础(§4.1)。可装载Merkle树(MMT)是一种新的物理内存保护抽象，用于实现可扩展的内存完整性和加密保护(§4.2)。高速缓存行（cache line）锁定是一种高速缓存分区扩展，用于防御基于高速缓存的旁路攻击(§4.4)。

## 细粒度内存隔离

![](https://cdn.jsdelivr.net/gh/wangzhankun/img-repo/boxcnKRE4LkyRZ3N1dXALCOzPqp.png)

“For fine-grained and flexible memory isolation, the secure monitor maintains an ownership bitmap to record the status of each physical page: secure for monitor and enclaves, nonsecure for untrusted OS and applications, and TreeNode for SubTrees (details in §4.2).” (Feng 等, 2021, p. 278) 

要分配安全页面，安全监视器需要在位图中更新它们的所有权。所有权位图由硬件(例如，RISC-V PMP)保护。

“To this end, we put all host page tables (Figure 2) in a protected memory region: Host Page Table Area (HPT Area), and trap any modification in HPT Area to ensure that no secure page will be mapped by any page tables of untrusted software.” (Feng 等, 2021, p. 278) 

“If the address of any PT page is out of HPT Area and the software currently running is not an enclave, the CPU will raise an exception to the monitor for further check.” (Feng 等, 2021, p. 279) 

要实现这个目的就需要修改CPU的page table walker，要不然CPU怎么知道要检查什么以及触发异常呢？此外作者设计了`reg_hptarea_start`和`reg_hptarea_size`两个寄存器用于指定HPT Area的起始地址和大小。

“When the OS updates address mappings, the request will be redirected to the secure monitor, which ensures the new page table entry does not point to a secure page. Also, we need to prevent the OS from bypassing such checking via stale TLB entries or disabling page table.” (Feng 等, 2021, p. 279) 当操作系统更新地址映射时，请求将被重定向到安全监控器，以确保新的页表条目不指向安全页。此外，我们还需要防止操作系统通过陈旧的TLB条目或禁用页表来绕过此类检查。

Enclave页表被标记为安全内存，并与HPT区域分开。安全监视器维护所有Enclave页表，每个Enclave可以映射自己的安全内存以及与操作系统共享的非安全内存。

## 可拓展内存完整性保护

### 问题

1. 大规模安全存储的完整性保护造成完整性树的高度非常高，这需要额外的带宽来加载树节点。
1. 为了提高内存完整性检查，明智的内存完整性引擎可以在CPU缓存中缓存最顶层的树节点。然而，它只能线性地增加安全内存量。
1. 即使没有使用安全内存，完整性引擎也需要预先分配额外的内存来存储所有树节点。最后，最先进的内存保护方案只能保护固定范围的内存，而软件根本无法管理安全内存。

MMT引入了一种可装载的子树结构，用于完整性树方案，并可以减少片上和内存中的存储开销。此外，MMT允许软件参与内存保护管理，并按需分配具有完整性保护的安全内存。

### 解决方案

关于Merkel tree在完整性度量中的应用可以参考 **Using Address Independent Seed Encryption and Bonsai Merkle Trees to Make Secure Processors OS- and Performance-Friendly**



![](https://cdn.jsdelivr.net/gh/wangzhankun/img-repo/boxcnG5IAlhc7hp8jjftwdNp3Oc.png)



![](https://cdn.jsdelivr.net/gh/wangzhankun/img-repo/boxcn3vUo1YbOfVBs2TElK0Tl1b.png)







![](https://cdn.jsdelivr.net/gh/wangzhankun/img-repo/boxcnSpP7WgFdVfgblPTNMZHJEc.png)









## 使用shadow fork初始化安全内存

蓬莱遵循了最近提出的无初始化启动[50]的想法，该启动过程利用Fork跳过初始化成本，但面临两个挑战：1)Enclave系统中的内存共享不安全，2)即使使用Fork，证明成本仍然保持不变。蓬莱提出了影子fork和影子enclave来克服这两个问题。

### Shadow fork

Shape Fork基于一种特殊的Enclave(不可运行)，Shadow  Enclave，这是一个干净的模板，用于通过派生新实例来加速启动。影子飞地是唯一可以fork的实体，并且只包含代码和数据段。在fork过程中，蓬莱监控器将共享read-execute代码和read-only段，复制其他可写部分，基于Shadow   Enclave初始化新实例的堆栈。由于启动的主要成本来自Enclave内存初始化(hash measurement)，因此可以接受对可写数据进行内存复制。在fork之后，创建的Enclave可以动态地将不受信任的操作系统的内存分配为堆或mmap区域

### Lightweight attestation

减少启动期间的证明成本是基于观察结果：计算内存度量值占用了证明中的大部分时间(例如，>90%)，如图11(B)所示。为了减少这种开销，监视器将提前计算阴影飞地的测量值(创建阶段)。用户可以通过包含密封的Enclave度量和用户的公钥(类似于SGX[23])的清单来利用enclave_fork。稍后，监视器将解封Enclave测量值(使用用户的公钥)，并将其与阴影Enclave的测量值进行核对。如果测量值匹配，则监视器将基于阴影飞地派生一个新实例。否则，监控器将拒绝该请求。因此，我们可以降低启动关键路径期间的证明成本。

## On-demand CacheLine Locking

安全敏感区域由飞地决定。当Enclave需要缓存隔离保护时，它会向monitor发出请求。两条特权指令：CACHE_LINE_LOCK和CACHE_LINE_UNLOCK，帮助监视器管理缓存线锁定状态。具体地说，高速缓存线锁定机制将高速缓存线指定给每个CPU核。CPU核心只能在高速缓存未命中期间逐出其高速缓存线，并且其他核心不能再逐出这些高速缓存线。

# 实现

![](https://cdn.jsdelivr.net/gh/wangzhankun/img-repo/boxcnfnQiyZFh3TVRIrwXb63ZUf.png)

在硬件扩展方面，我们修改了核内(Rocket  Core)和核外(Memory控制器)硬件资源，以支持保护页表和可挂载Merkle树。在软件扩展方面，我们实现了一个微小而安全的监视器，一个支持HPT区域分配器的扩展的Linux内核，一个Enclave驱动程序和一些运行Enclaves所需的库。

在RISC-V的机器模式下，我们在OpenSBI[18]和Berkeley Boot  Loader(BBL)[17]上实现了安全监视器。安全监视器包括Enclave管理、硬件扩展管理、内存检查以及加密库，加密库增加了6,399个LoC。我们遵循Sancum[45]来使用防篡改软件方法(BootLoader作为信任的根)实现安全引导。如图7所示，就在机器启动后，引导加载器将首先派生证明密钥并初始化MMT引擎。MMT元区也将在此阶段进行初始化。在所有这些早期配置之后，引导加载程序将加载并计算安全监视器的测量值。MMT引擎还对监视器的内存执行完整性和加密保护。在此之后，安全监控器控制并加载Linux内核作为其有效负载。

我们扩展了Linux内核(版本：4.4.0/5.10.2)以支持蓬莱。有两个主要的修改：(1)HPT区域分配器，(2)劫持每个PTE设置。首先，在初始化内存管理后，内核将分配一个连续的物理内存作为HPT区域，并将init_pt复制到其中。一个专用分配器将管理HPT区域中的所有页面，并负责每个页表的分配。

服务器飞地没有正在运行的上下文(例如，时间片、调用处理程序)，而是从其他飞地继承上下文。因此，服务器飞地不能单独运行。在创建服务器飞地时，需要为其分配唯一的名称作为其标识。其他飞地可以使用其唯一的服务器名称获取该服务器飞地的句柄。此外，服务器Enclave还可以执行操作系统的部分功能。例如，我们可以在服务器飞地中运行文件系统服务器来处理所有与文件系统相关的请求。将OS功能从不可信的OS分离到可信的飞地服务器可以减轻由不可信的特权发出的Iago攻击的风险[41]。

蓬莱支持Enclave与服务器Enclave(E-E)、主机与Enclave(H-E)之间的IPC，基于两种机制：共享内存和中继页[49]。共享内存是基本的通信方式。安全监视器可以将共享内存映射到主机和Enclave，或Enclave和服务器Enclave。中继页是一种新的通信机制，如图8所示，安全监视器确保一个页只能同时为一个所有者映射。该机制可以减少E-E和H-E之间的TOCTTOU(检查到使用时间)等安全问题，实现零拷贝通信。蓬莱还可以支持飞地之间的同步和异步IPC。对于同步IPC，调用方飞地将等待被呼叫方飞地返回。对于异步IPC，调用方Enclave将立即返回，参数将在开始运行时传递给被调用方Enclave。

# **实验**

# **结论**

# **未来与展望**

# **强相关参考论文**

|论文名称 |摘要/说明 |
|---|---|
| | |
| | |
| | |
| | |
# 其它相关材料



