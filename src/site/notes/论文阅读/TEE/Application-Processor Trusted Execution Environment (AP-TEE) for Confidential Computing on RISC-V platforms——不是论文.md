---
{"dg-publish":true,"permalink":"/论文阅读/TEE/Application-Processor Trusted Execution Environment (AP-TEE) for Confidential Computing on RISC-V platforms——不是论文/","dgPassFrontmatter":true}
---


# Application-Processor Trusted Execution Environment (AP-TEE) for Confidential Computing on RISC-V platforms——不是论文

# **摘要**



# **论文研究目标**

This specification aims to describe the TEEI and TSM interfaces.

## **问题**

## 贡献

# 术语表

|TEE Virtual Machine |TVM | |
|---|---|---|
|TEE Security Manager |TSM | |
|Trusted Execution Environment Interface |TEEI | |
|Physical memory attributes |PMA | |
|Memory Tracking Table |MTT | |
|Root-of-trust for Measurement |RTM | |
|Root-of-trust for Reporting |RTR | |
| | | |
# **方法**

## Overview

### VM workloads

![](/img/user/论文阅读/TEE/assets/boxcngVjnfyb5nljHaPJSi6FeIf.png)

TEE地址空间可以由机密区域和非机密区域组成。前者既包括measured pages(包含初始TVM的一部分)，也包括可以在TVM进行运行时访问之后由VMM按需分配的机密zero-pages。非机密TVM定义区域包括用于共享页面和MMIO的区域。

TSM运行在HS-mode，允许OS/VMM（也运行在HS-mode）创建TVM，并为TVM分配资源，管理、执行、销毁TVM。

TSM驱动（M-mode）借助硬件能力提供的功能有：

* 将分配给TEE的内存进行隔离。TEE相关的内存提供了：访问控制、机密性、完整性的功能。
* 在TEE与non-TEE之间进行hart状态的上下文切换
* 将与机器无关的ABI作为TEEI的一部分，以允许较低权限的软件以与操作系统和平台无关的方式与TSM驱动程序交互。

TSM驱动将部分TEE得管理功能交给了TSM，尤其是内存隔离功能。TSM向OS/VMM提供ABI，其具有两个方面：TH-ABI，其包括以OS/平台不可知的方式管理TVM的生命周期的功能，例如创建TVM、向TVM添加页面、调度TVM以供执行等。TSM还向TVM上下文提供了TG-ABI，以使TVM工作负载能够请求证明功能、内存管理功能或半虚拟化IO功能。

为了将TVM与非机密得VM隔离开来，需要将TSM的状态进行隔离，这可以通过增强TSM内存页的隔离性来实现。TSM内存区域是静态内存区域，存储TSM的代码和数据，可以使用加密的方法抵御物理攻击。每一个hart都维护一个AP-TEE mode bit（本spec未实现），通过该标志位可以知道当前是否在访问TSM内存区域以及当前执行的指令是否是TSM内存中的指令。

安全原语要求TSM强制进行TVM虚拟HART的状态保存和恢复，以及强制为分配给TVM的内存实现不变性(包括阶段2转换)。主机OS/VMM为内存、IO等提供典型的VM资源管理功能。

### Process workloads

![](/img/user/论文阅读/TEE/assets/boxcnmCx8mggByCgxjB6GI506wt.png)

## 结构细节

### AP-TEE内存隔离

APTEE需要新的物理内存属性(PMA)：机密和非机密(这些是动态/可编程内存属性[PRIV  ISA])。TVM同时拥有两种类型的内存：

* ·机密内存-具有机密PMA-用于TVM代码、数据·非机密内存
* 非机密PMA-用于TVM和不受信任的主机实体之间的通信

TEEI实现了内存在机密与非机密之间的转换。

* AP-TEE标志位为1的hart允许访问机密和非机密内存
* AP-TEE标志位为0的hart只允许访问非机密内存

![](/img/user/论文阅读/TEE/assets/boxcnjyOvlIs69Yoxyxm72tlH3c.png)

非机密内存由VMM管理，机密内存由TSM和TSM驱动通过Memory Tracking Table(MTT)进行管理。

![](/img/user/论文阅读/TEE/assets/boxcnlk0Z5BxZcESf1JVln8xi5b.png)

Two-stage address translation参见[^1]。

* TEE指令fetch：TVM/TSM不能从不安全的共享内存中获取指令
* TEE paging structure walk: TVM/TSM不能再不受信任的共享内存中定位页表
* TEE data fetch: TVM/TSM允许TVM/TSM放宽对非机密内存的数据访问(通过MTT)，以允许IO访问。

在机密内存转换或回收期间，TCB必须强制不受信任的主机或其他TVM上下文无法访问缓存在HART中的陈旧转换。在向TVM分配机密存储器期间(或在将机密存储器转换为共享存储器期间)，TCB必须强制不能将过时的转换保留到由TVM产生的存储器(并且由主机用于另一TVM或VM或主机)。这些属性由TSM与HW TCB通过建议的TEEI一起实施。

在平台初始化期间，HW  元素构成了测量  TSM  驱动程序的  RTM。  TSM  驱动程序充当平台上加载的  TSM  的  RTM。  TSM  驱动程序为 TSM  初始化  TSM  内存区域  ‑  此  TSM  内存区域必须位于支持  TEE  的内存中。

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

[^1] WATERMAN A, ASANOVIC K, HAUSER J, 等. Volume II: Privileged Architecture[J].



