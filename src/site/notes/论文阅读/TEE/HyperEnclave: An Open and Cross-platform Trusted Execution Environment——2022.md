---
{"dg-publish":true,"permalink":"/论文阅读/TEE/HyperEnclave: An Open and Cross-platform Trusted Execution Environment——2022/","dgPassFrontmatter":true}
---


# HyperEnclave: An Open and Cross-platform Trusted Execution Environment——2022

# **摘要**

我们提出了HyperEnclave,开放和跨平台的基于进程的模型,依赖于将虚拟化扩展创建独立的执行环境。特别是HyperEnclave旨在支持灵活的飞地操作模式来满足各种飞地工作负载下的安全性和性能的要求。HyperEnclave可以在没有SGX、SEV的计算机上创建enclave。但是要求计算机系统有TPM进行安全启动。

# **论文研究目标**

## **问题**

1. 目前的TEE是闭源的，依赖于硬件或者固件，很难进行审计，迭代更新慢
1. 此外，大多数现有的TEE设计将飞地(即受保护的TEE区域)限制为只能在固定模式下运行。很难支持需要TEE保护的各种类型的应用的性能和安全需求。

## 贡献

我们的设计提供了一个基于进程的模型，使用虚拟化扩展(隔离)和TPM(根的信任和随机性等)。为了更好地满足特定的需要飞地工作负载,HyperEnclave支持灵活的飞地的操作模式,即。飞地可以运行在不同的特权级别,可以获得某些特权的资源。

在我们的设计中,系统运行在三个模式。monitor mode, normal mode, secure mode。

1. monitor mode: 一个可信的软件层,称为RustMonitor(安全监视器),在监控模式下运行,运行在VMX的根模式。RustMonitor负责执行隔离和是可信计算基础的一部分(TCB)。
1. normal mode: 不可信操作系统(称为主操作系统)为应用程序不受信任的部分提供了一个执行环境;不可信的操作系统和应用程序部件在正常模式下运行,这是映射到VMX非根模式。
1. secure mode: 受信任的应用程序的一部分(即。飞地)运行在安全模式下,可以灵活地映射到ring3或ring0的VMX根模式,或ring3的VMX根模式。

我们的内存隔离方案通过由完全受信任的代码管理飞地的页表和page-fault,移除了主操作系统的参与。

|ENCLAVE OPERATION MODE |VMX Mode与特权级 |运行的代码 |
|---|---|---|
|Monitor Mode |VMX 根模式 |RustMonitor |
|Normal Mode |VMX非根模式
ring0 for primary OSring3 for untrusted part of app |主操作系统和应用程序不受信任的部分 |
|Secure Mode |VMX根模式的ring3或者ring0，VMX非根模式的ring3 |根据飞地的操作模式选择运行在VMX根模式的ring3或ring0，或者是非根模式的ring3 |




## 威胁模型

像其他TEE的建议,我们信任底层硬件,包括处理器建立的virtualization-based隔离,系统管理模式(System  Management  Mode)代码,以及TPM。我们假设的信任根(CRTM)是可信的和不可改变的。HyperEnclave能够缓解某些物理内存的攻击,如冷启动攻击和在支持内存加密的硬件上的总线窥探攻击的。假设攻击者不能在引导过程中进行物理攻击,即。最初,我们假设系统是良性的(在系统启动),早期的操作系统在启动阶段是TCB的一部分。这可以通过两种方式实现：

1. 启动阶段由硬件保证安全启动
1. 在启动阶段，为防止IO攻击，可以在IOMMU之前禁用DMA并移除一切不必要的外设。在早期（比如在BIOS中）就启用内存加密功能以阻止物理内存攻击。

但是，启动RustMonitor后，主操作系统将降级到正常模式，并可能处于攻击者的控制之下，攻击者可能会尝试危害RustMonitor或Enclaves，例如，尝试直接或通过DMA访问受保护的内存。我们认为Enclave代码可能是恶意的，或者由于内存错误而被攻击者控制。我们的设计需要防止受威胁的飞地污染其他飞地或RustMonitor。我们还可以防止针对主操作系统或应用程序代码的攻击，如[63]中所述。与其他TEE类似，本文并不关注对拒绝服务(DoS)攻击或侧通道攻击的预防，如缓存定时攻击和推测执行攻击。

# **方法**

![](/img/user/论文阅读/TEE/assets/boxcnocxM0JwUcImrEPFyBmLi4b.png)

## 模块

|RustMonitor |Monitor Mode |轻量级Hypervisor，用于管理enclave memory，控制enclave的状态转移 |
|---|---|---|
|Primary OS |Normal Mode |运行在RustMonitor创建的VM中，用于部署APP不受信任的部分，负责进程调度、IO处理，不被RustMonitor和飞地信任 |
|Untrusted part of APP |Normal Mode |运行在Primary OS中 |
|Kernel module |Normal Mode |运行在Primary OS中，用来加载、度量和启动RustMonitor |
|Enclave SDK | |兼容Intel SGX的API，包括untrusted runtime (SDK uRTS)以及trusted runtime (SDK tRTS) |
|Trusted part of APP |Secure Mode |运行在飞地中 |
## 内存管理与隔离

![](/img/user/论文阅读/TEE/assets/boxcnJKMjhPfnTigdyg5UfJCQ9p.png)

在SGX中，enclave的内存也是由OS进行管理的，这引入了很多问题。HyperEnclave则是让RustMonitor管理enclave的内存，包括页表的建立以及page fault的处理等。但是，enclave依然与不受信任部分的代码处在同一个内存空间中。然而，这种设计面临着新的挑战：由于enclave可以访问应用程序的整个地址空间，当应用程序的页表映射发生变化时，例如由于页面交换，更新后的映射需要与RustMonitor管理的enclave的页表同步。为了消除同步开销，我们在应用程序的地址空间中预分配了一个marshalling缓冲区，该缓冲区与Enclave共享。marshalling缓冲区的映射在整个Enclave生命周期中是固定的，方法是预先分配物理内存并将其固定在内存中。飞地之间、飞地与应用程序之间交换数据必须通过marshalling buffer。enclave不需要应用程序的内存映射,也不不包含在飞地的页表。

### 安全规则

HyperEnclave 强制实施以下安全要求：

1. 主操作系统和应用程序不允许访问属于 RustMonitor 和 enclave 的物理内存。
1. enclave 不允许访问属于 RustMonitor 和其他 enclave 的物理内存。它被设计为只能访问与不可信应用程序共享的特定内存区域，用于参数传递（即编组缓冲区）。
1. 不允许恶意外设通过 DMA 访问属于 RustMonitor 和 enclave 的物理内存。为了防止这种攻击，HyperEnclave 借助现代处理器中的输入输出内存管理单元（IOMMU）的支持限制了外设使用的物理内存。

## 可信启动、证明与Sealing

![](/img/user/论文阅读/TEE/assets/boxcn8XlA5AKx19FGTwYxwUWC7e.png)



为减少来自主操作系统的攻击,我们把RustMonitor放入了initramfs中。

RustMonitor加载后,在预定义的入口继续执行。RustMonitor建立自己的运行环境(如栈,页表,IDT,等等)，为每个CPU准备虚拟CPU(vCPU)。然后RustMonitor正常启动VM和并将主操作系统降级至正常模式。之后回到内核模块,内核继续正常启动,无法感知RustMonitor的存在

### 远程证明

RustMonitor启动后,它需要将信任拓展至飞地。为此,RustMonitor派生一个认证密钥对用于飞地测量标志。RustMonitor把派生出的公钥拓展进了TPM的PCR，私钥则保存在内存中（内存是被AMD SME或者Intel MKTME加密的）。

在Enclave创建期间，RustMonitor会度量添加到Enclave的所有页面(包括相应的页面内容、页面类型和RWX权限)以生成Enclave度量值。

类似于TPM和英特尔新交所,HyperEnclave采用SIGn-and-MAc(SIGMA)认证协议的远程认证流程

### 私钥生成

RustMonitor首次初始化时,它会从随机数字生成器(RNG)模块TPM生成一个根密钥，。Kroot使用TPM的密封操作存储在TPM之外。



## 
Enclave SDK

飞地代码被编译成应用程序的受信任的库,而应用程序本身运行在主操作系统。飞地生命周期管理通过模拟一组SGX特权指令完成(即：EADD ECREATE EINIT,等等)。运行在主操作系统的内核模块通过虚拟化指令调用RustMonitor类似的功能,并将这些功能通过ioctl()的应用程序接口暴露给飞地代码。通过模拟SGX指令,RustMonitor负责飞地的生命周期的管理。

## Enclave Operation Mode

![](/img/user/论文阅读/TEE/assets/RVutbOj6QoHCjWxFnT2c3wltntb.png)





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



# 问题

## 为什么不直接在启动时就按照TYPE-1类型启动呢？而是先按照TYPE-2类型启动，运行时是TYPE-1？

## “When RustMonitor is initialized for the first time, it generates a root key Kroot from the random number generator (RNG) module of the TPM. Kroot is stored outside the TPM using TPM’s seal operation.”所以Kroot究竟存储在哪里，存储在硬盘上吗？

## “RustMonitor floods the PCRs with a constant before transferring control to the primary OS to prevent it from retrieving Kroot” 搞不懂怎么对TPM的PCR进行flood。如果可以的话，那么是否可能在RustMonitor也对PCR进行flood呢？这是不是就是破坏了可信启动过程呢？



## Kernel module 是如何启动RustMonitor

