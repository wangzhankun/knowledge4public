---
{"dg-publish":true,"tags":["论文","TEE"],"permalink":"/论文阅读/TEE/CURE A Security Architecture with CUstomizable and Resilient Enclaves/","dgPassFrontmatter":true}
---


# CURE: A Security Architecture with CUstomizable and Resilient Enclaves——2021

# **摘要**

首先，他们遵循一刀切的方法，只提供单一的飞地类型，然而，不同的服务需要灵活的飞地，可以根据他们的需求进行调整。其次，它们不能有效地支持新兴应用程序(例如，机器学习即服务)，这些应用程序需要到外围设备(例如，加速器)的安全通道，或多核的计算能力。第三，它们对缓存侧通道攻击的保护要么是事后考虑的，要么是不切实际的，即在缓存资源和单独的飞地之间没有提供细粒度的映射。

我们提供不同类型的飞：(I)子空间飞地（sub-space enclave）在所有执行特权级别上提供垂直隔离；(Ii)用户空间飞地(user-space enclave)为非特权应用程序提供隔离执行；以及(Iii)自包含飞地(self-contained enclave)允许跨多个特权级别的隔离执行环境。此外，CURE允许将系统资源(例如，外围设备、CPU核心或缓存资源)独占地分配给单个飞地。

# **论文研究目标**

## **问题**

首先，他们遵循一刀切的方法，只提供单一的飞地类型，然而，不同的服务需要灵活的飞地，可以根据他们的需求进行调整。其次，它们不能有效地支持新兴应用程序(例如，机器学习即服务)，这些应用程序需要到外围设备(例如，加速器)的安全通道，或多核的计算能力。第三，它们对缓存侧通道攻击的保护要么是事后考虑的，要么是不切实际的，即在缓存资源和单独的飞地之间没有提供细粒度的映射。它还通过灵活和细粒度的缓存资源分配提供旁路保护。

## 贡献

1. 我们提出了CURE，这是我们为灵活的TEE体系结构设计的与体系结构无关的新型设计，它可以在多种飞地类型中保护未经修改的敏感服务，范围从用户空间中的飞地、子空间飞地到包括特权软件级别和支持飞地到外围设备绑定的独立(多核)飞地。
1. 我们为CPU内核、系统总线和共享缓存引入了新的硬件安全原语，只需最少且非侵入性的硬件修改。

# 威胁模型

我们的对手模型遵循TEE体系结构通常假定的模型，即，一个强大的纯软件对手，它可以危害包括OS在内的所有软件组件，但可信计算基础(TCB)除外。TCB配置系统的硬件安全原语，管理飞地，并且本质上是可信的。

我们假设对手的目标是从TCB或受害者飞地泄露秘密信息。完全控制系统软件的对手可以将自己的代码注入内核(PL2)，甚至注入hypervisor(PL1)。这使得攻击者能够完全访问用于设置飞地的TCB接口，从而产生恶意进程，甚至飞地。即使对手不能更改固件代码(使用安全引导)，代码中仍可能存在内存损坏漏洞，并可被对手利用[24]。此外，我们假设攻击者能够从软件中危害外围设备以执行DMA攻击。

我们假设底层硬件是正确和可信的，因此排除了利用硬件缺陷的攻击[40，86]。我们也不假定物理访问，因此，故障注入攻击[6]、物理侧通道攻击[46，62]或恶意外围设备的物理连接都不在范围之内。我们不考虑拒绝服务(DoS)攻击，在这种攻击中，对手可以饿死一块飞地，因为控制操作系统的对手可以很容易地关闭整个系统。作为TEE体系结构的标准，CURE不能防止Enclave代码中的软件可利用漏洞，但可以防止它们的利用危及整个系统。

# **方法**

## 生态

每个服务提供者都会创建一个包含所需硬件资源、版本号、enclave标签等信息的配置文件，并将enclave binary、配置文件、host app打包通过app store分发给用户。每个app的enclave标签（$L_{enclave}$）都是独一无二的。

服务提供者创建一对密钥（$SK_{p}, PK_{p}$），app store提供一个签名证书$Cert_p$，服务提供者使用私钥将enclave binary和配置文件进行签名并附加到$Cert_p$中。证书$Cert_p$可以被设备用来验证签名。为了正确验证签名，app store的根证书以及验证链（$Chain_p$）上的所有证书都必须存在于设备上，并且不可篡改。

设备提供商为每一个设备都提供独一无二的公私钥对$SK_{d}, PK_{d}$，设备供应商也需要提供一个公钥证书$Cert_d$用于远程证明以验证设备的合法性。因此，服务提供商也必须获得一个证书链一直绑定到设备供应商的根证书。当一个设备被破坏了，该设备的证书$Cert_d$也要被撤销。

## Enclave

下图中的$Encl_1$是user-space enclave，$Encl_2$是only kernel-space enclave，$Encl_3$是both kernel and user space enclave

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/boxcna7OHrPlcDzqkoZ6xd9lLud.png)

### enclave管理

SM由安全启动负责验证。SM运行在M-MODE。我们假设SM已经将其回滚保护状态𝑆𝑠𝑚加载到易失性主存储器中。SM状态包含设备上安装的每个飞地的𝑆𝐾𝑑、𝑃𝐾𝑑、𝐶𝑒𝑟𝑡𝑑、𝐶ℎ𝑎𝑖𝑛𝑝和结构𝐷𝑒𝑛𝑐𝑙

### enclave安装

当Enclave部署到设备时，SM首先使用$Cert_p$和证书链$𝐶ℎ𝑎𝑖𝑛_𝑝$验证$Sig_{encl}$。然后，SM创建新的Enclave元数据结构$𝐷_{𝑒𝑛𝑐𝑙}$，并在其中存储$𝐿_{𝑒𝑛𝑐𝑙}$、$𝑆𝑖𝑔_{𝑒𝑛𝑐𝑙}$和$𝐶𝑒𝑟𝑡_𝑝$。此外，SM创建用于持久存储所有敏感的飞地数据的飞地状态结构体$𝑆_{𝑒𝑛𝑐𝑙}$。SM还创建经过验证的加密密钥$𝐾_{𝑒𝑛𝑐𝑙}$，该密钥用于在将飞地状态存储到磁盘或闪存时保护飞地状态。$𝐾_{𝑒𝑛𝑐𝑙}$和$𝑆_{𝑒𝑛𝑐𝑙}$也存储在$𝐷_{𝑒𝑛𝑐𝑙}$中。最初，$𝑆_{𝑒𝑛𝑐𝑙}$仅包含由SM创建的经认证的加密密钥$𝐾_{𝑐𝑜𝑚}$和单调计数器，飞地使用该密钥来加密保护传送到不可信OS的数据。飞地元数据结构$𝐷_{𝑒𝑛𝑐𝑙}$还包含用于回滚保护飞地状态的单调计数器。

enclave元数据结构$D_{encl}$包含的数据有：一个单调计数器、$K_{encl}$、$S_{encl}$、$L_{encl}$、$Sig_{encl}$、$Cert_p$。

其中$S_{encl}$包含数据：一个单调计数器、$K_{com}$

### 启动enclave

### 执行enclave

### User-space enclave

U-Enclave依赖于OS的内存管理、异常/中断处理、系统调用等。OS可以正常调度user-space enclave，但是上下文切换由SM负责。

“CURE defends against these attacks by moving the page tables of user-space enclaves into the enclave memory. More subtle controlled side-channel attacks exploit the fact that the enclave’s interrupt handling is performed by the OS [91]. CURE also mitigates these attacks by allowing each enclave to register trap handlers to observe its own interrupt behavior, and act accordingly if a suspicious behavior is detected” (Bahmani 等, 2021, p. 1078) Cure通过将用户空间飞地的页表移动到飞地内存来防御这些攻击。更微妙的受控侧通道攻击利用了飞地的中断处理由OS执行的事实[91]。CURE还通过允许每个飞地注册陷阱处理程序来观察自己的中断行为，并在检测到可疑行为时采取相应行动，从而缓解了这些攻击。

### Kernel-space enclave

内核空间飞地的关键特征是它能够在特权(PL2)软件层或甚至在hypervisor级别(PL1)中的CPU核心上裸机运行代码(如果可用)。因此，操作系统服务，例如内存管理，可以在Enclave的运行时(RT)组件中实现(图2)。这导致与不信任的OS的资源共享较少，因此更容易防止受控的侧通道攻击[91、92、101]。此外，通过将设备驱动程序包括到RT中，可以建立到外围设备的安全通信通道。此外，由于CURE允许跨多个内核运行内核空间飞地，因此内核空间飞地提供了更强的计算能力。

### Sub-space enclave

“In CURE, sub-space enclaves are used to isolate the SM from the firmware code to protect against exploitable memory corruption vulnerabilities that might be present in the firmware code [24]. Moreover, hardware countermeasures, described in Section 5.3, are used to prevent the firmware code from accessing the SM data or hardware primitives.” (Bahmani 等, 2021, p. 1078) 在CURE中，子空间飞地用于将SM与固件代码隔离，以防止固件代码中可能存在的可利用的内存损坏漏洞[24]。此外，第5.3节中描述的硬件对策用于防止固件代码访问SM数据或硬件原语。

## 硬件安全原语

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/boxcnSa8MJNp4Czlylq8tBvqWVb.png)

### 定义enclave执行上下文



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



