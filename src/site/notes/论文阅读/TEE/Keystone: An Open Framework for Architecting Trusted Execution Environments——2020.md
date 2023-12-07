---
{"dg-publish":true,"permalink":"/论文阅读/TEE/Keystone: An Open Framework for Architecting Trusted Execution Environments——2020/","dgPassFrontmatter":true}
---


# Keystone: An Open Framework for Architecting Trusted Execution Environments——2020

# **摘要**

Keystone: the first open-source framework for building customized TEEs.

Keystone 使用了硬件提供的抽象：内存隔离、可编程层。我们在这些抽象之上构建了可重用的TEE，允许根据平台特性进行修改和定制。在本文中，我们在未经修改的risc-v平台上实现了keystone。

# **论文研究目标**

## **问题**

1. 需要在不可信的OS之下提供一个可编程的可信层
1. 必须将隔离机制与资源管理、虚拟化、可信边界解耦合
1. hypervisor的解决方案将安全功能与虚拟化耦合在了一起
1. firmware和micro-code级别的修改是不可编程的



目前市面上的商用TEE系统提供的威胁模型与硬件平台相关，缺乏灵活性。值得注意的是，英特尔的SGX[64]并不支持其内存保护系统的任何配置，这在不需要昂贵的内存加密的用例中是不可取的。另一方面，虽然ARM的TrustZone提供了一些软件和硬件的定制化，但其提供的模块化TEE基础较差。TrustZone的设计核心是仅有两个安全域的概念。实现多个enclave的TrustZone   TEE必须使用内存管理单元(MMU)进行进一步隔离。这从根本上限制了enclave可以执行的操作，将enclave限制在用户模式下。这个限制自然延伸到所有使用TrustZone作为基础的TEE系统，例如Komodo。在硬件方面，TrustZone依赖于系统范围的总线地址过滤器（例如TZC-400）来将安全的DRAM分区与不安全的DRAM分区分开，而RISC-V通过机器模式和PMP寄存器提供每个硬件线程对物理内存的独立视图。因此，使用RISC-V可以让多个并发和潜在的多线程enclave访问不同的内存分区，同时还可以打开监管者模式和MMU供enclave使用。这允许一个enclave包含一个轻量级的监管者模式OS，甚至是一个完整的监管者模式OS，正如我们所演示的那样。



## 贡献

我们使用机器模式来执行可信安全监视器(SM)来提供安全边界，而不需要执行任何资源管理。重要的是，每个Enclave都在自己的隔离物理内存区域中运行，并拥有自己的supervisor-mode的运行时(RT)组件来管理Enclave的虚拟内存等。有了这种新颖的设计，任何Enclave特定的功能都可以由其运行时实现，而SM则管理硬件强制的保证。Enclave的RT仅实现所需的功能，与SM通信，通过共享内存协调与主机的通信，并服务enclave user-mode application(EAPP)。

Keystone的SM使用硬件原语为TEE(如安全引导、内存隔离和证明)提供支持。RT（运行时）为系统调用接口、标准libc、Enclave内虚拟内存管理、自我分页等提供功能模块。为了加强安全性，我们的SM利用任何可用的可配置硬件来组成额外的安全机制。我们通过高度可配置的缓存控制器展示了这一点的潜力，它可以与PMP配合使用，透明地防御物理对手和缓存侧信道攻击。

Keystone不需要更改CPU核心、内存控制器等。支持Keystone的安全硬件平台需要：仅对可信引导过程可见的特定于设备的密钥、硬件随机数发生器和可信引导过程。密钥供应[15]是一个正交问题。对于本文，我们假设一个制造商提供的密钥。

# **方法**

## 设计原则

1. 利用可编程层和隔离原语进行保护。设计了安全监视器SM利用M-mode的四个性质来实现TEE：
1. 解耦合资源管理和安全检查。我们的S模式运行时(RT)和U模式Enclave应用程序(EAPP)都驻留在Enclave地址空间，与不受信任的操作系统或其他用户应用程序隔离。RT管理在Enclave中执行的用户代码的生命周期，管理内存、服务系统调用等。为了与SM通信，RT通过RISC-V管理程序二进制接口(SBI)使用一组有限的API函数来退出或暂停Enclave(表1)，以及代表EAPP请求SM操作(例如，证明)。每个Enclave实例可以选择自己的RT，而不会与任何其他Enclave共享。
1. 设计模块化的层。Keystone使用模块化(SM、RT、EAPP)来支持各种工作负载。它使Keystone平台提供商和Keystone程序员不必将他们的需求和遗留应用程序改造成现有的TEE设计。每一层都是独立的，为其上面的层提供了安全感知的抽象，实施了可由较低层轻松检查的保证，并与现有的特权概念兼容。
1. 允许细粒度TCB配置。对于给定的特定用例，Keystone可以用最小的TCB实例化TEE。Enclave程序员可以通过RT  CHOICE和使用现有用户/内核特权分离的EAPP库进一步优化TCB。例如，如果EAPP不需要libc支持或动态内存管理，Keystone将不会将它们包括在Enclave中。

## 威胁模型



## Security Monitor

[RISC-V PMP物理内存保护机制详解](https://zhuanlan.zhihu.com/p/139695407)

### 内存隔离

SM启动时，将第一个PMP配置成SM独占的内存区域。将最后一个PMP设置成所有的OS都可以访问的内存区域。

当请求创建enclave时，OS会找到一片合适的连续的物理内存。SM在验证请求之后会将这块内存配置在PMP中以禁止其它进程/OS访问。

在传递控制给保护区时，SM（仅适用于当前核心）：(a) 启用相关保护区内存区域的PMP权限位；(b) 删除所有OS PMP条目的权限，以保护所有其他内存免受保护区的攻击。这允许保护区访问其自己的内存，而不会访问其他区域。在CPU上下文切换到非保护区时，SM禁用保护区域的所有权限，并重新启用OS PMP条目，以允许OS进行默认访问。在保护区被销毁时，保护区PMP条目被释放。

Keystone使用操作系统生成的页表进行初始化，然后在执行期间将虚拟内存到物理内存的映射完全委托给Enclave。

### 中断与异常

在Enclave执行期间，所有的中断会直接陷入到SM。异常(例如页面错误等)可以通过RISC-V异常委派寄存器安全地委派给RT。然后，RT按照实现标准内核抽象所需的方式处理异常，并且可以通过SM将其他陷阱转发到不可信的OS。为了避免持有核心的飞地对主机进行DoS攻击，SM在进入飞地之前设置机器计时器。当SM在定时器中断触发后重新获得控制时，它可以将控制权返回给主机OS或请求Enclave干净地退出。

### enclave生命周期

在创建时，keystone会度量enclave的内存确保OS正确加载了二进制文件。keystone度量的是虚拟内存空间。OS会初始化enclave的页表并为enclave分配物理内存。SM会遍历OS提供的页表检查是否有非法的映射。之后SM会对enclave页面的内容计算哈希值。

在执行时，SM会配置PMP项并将执行权转移给enclave。

在销毁时，SMhi清除enclave内存空间，之后将内存交还给OS。

![](https://cdn.jsdelivr.net/gh/wangzhankun/img-repo/boxcnWQqlYVlRtr4R1p2X1y1s5d.png)

### Keystone支持的原语

1. Secure boot。SM image的安全性由安全启动保证。
1. Secure source of randomness
1. Remote attestation
1. Other primitives

## Keystone 运行时模块

在SM物理隔离每个enclave的情况下，我们可以安全地允许enclave运行私有S模式代码（即RT）。这为eapp提供了模块化的系统级抽象（例如虚拟内存管理）。尽管RT在功能上类似于enclave内部的内核，但它不需要大部分内核功能。我们构建了一个模块化的示例RT——Eyrie，允许enclave开发人员仅包含必要的功能并减少TCB。

### enclave内存管理

1. Free memory。由此，页面映射不需要在创建时预定义，未映射的内存区域不会包含被度量，而是会在eapp执行之前清零。
1. In-enclave self paging。该模块负责处理enclave的page-fault并且使用通用的page backing-store管理被释放的页面。
1. Protecting the page content leaving the enclave。当enclave的页面被换出时，需要对该页面进行加密处理。

### Functionality modules

1. Edge call interface. 用于处理enclave访问非enclave内存的读写操作。edge call类似于RPC，当enclave调用non-enclave函数时，需要传递参数，同时需要将返回值写入到enclave的内存。为了实现这个操作：
1. 多线程。我们通过将线程管理委托给运行时来运行多线程eapp。我们还不支持并行多核Enclave执行，但这可以通过允许SM在不同内核中多次调用Enclave执行来实现。



# 安全性分析

## enclave的保护

Keystone的认证功能保证在创建飞地时可以看到SM、RT和EAPP的任何修改。

**Mapping Attack**. RT由eapp信任，不会故意创建恶意的虚拟到物理地址映射[45]，并确保这些映射是有效的。RT在enclave创建期间初始化页面表，或加载预分配（并经SM验证的）静态映射。在enclave执行期间，RT确保在更新映射时不会破坏布局（例如，通过mmap）。当enclave获得新的空页面（例如通过动态内存调整）时，RT会检查它们是否安全，然后将它们映射到enclave。同样，如果enclave正在删除任何页面，则RT在将其返回给操作系统之前擦除其内容。

**Syscall Tampering Attacks.**如果EAPP和RT调用在主机进程中实现的不可信功能和/或执行OS系统调用，则它们容易受到Iago攻击和系统调用篡改攻击[32，77]。Keystone可以将现有的屏蔽系统[18，31，82]作为RT模块重新使用，以保护飞地免受这些攻击。

**Side-channel Attack.**

## Host OS的保护

我们确保主机操作系统不会受到来自Enclave的新攻击，因为Enclave：(A)由于SM  PMP强制隔离而无法访问其分配区域之外的任何内存；(B)无法修改属于主机用户级应用程序或主机OS的页表；(C)无法污染主机状态，因为SM执行完整的上下文切换(TLB、寄存器、L1缓存等)。(D)无法DOS内核，因为Enclave将被SM设置的机器定时器中断，从而SM可以将控制返回给OS。

## SM的保护

SM的内存区域受到PMP的保护，无法被攻击。

SM提供的SBI是潜在的攻击面。Keystone仅定义了很少的SBI，不进行任何复杂的资源管理，因此足够小，可以被形式化验证。SM仅仅是一个reference monitor，不需要被调度，因此不会出现Dos攻击。

## 物理攻击的防护

Keystone可以通过平台功能和对BootLoader的拟议修改来防御物理对手。

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



