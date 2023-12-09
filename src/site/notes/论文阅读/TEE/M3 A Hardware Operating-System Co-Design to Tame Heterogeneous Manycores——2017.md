---
{"dg-publish":true,"tags":["TEE","论文"],"permalink":"/论文阅读/TEE/M3 A Hardware Operating-System Co-Design to Tame Heterogeneous Manycores——2017/","dgPassFrontmatter":true}
---


# M3: A Hardware/Operating-System Co-Design to Tame Heterogeneous Manycores——2017

# **摘要**

1. 隐藏在公共硬件接口后面的异构性在很大程度上统一了操作系统中核心和加速器的控制和协调
1. 隔离在片上网络而不是处理器功能(如特权模式、内存管理单元、.。。)，允许在任意核上运行不受信任的代码
1. 通过网络协议提供OS服务-片上协议，而不是通过系统调用，使它们也可以被任意类型的核访问。

本文介绍了片上网络隔离的概念，给出了基于微内核的操作系统M3的设计和通用的硬件接口，并与Linux进行了性能比较。

# **论文研究目标**

## **问题**

1. 计算资源异构性
1. 加速器被视为设备（second-class），但是FPGA等异构计算单元越来越复杂且对网络、文件系统等有了更多需求
1. 计算核心越来越多

## 贡献

1. 我们引入数据传输单元DTU和NoC(network of chip)隔离的概念,使统一的控制和协调异构处理器。
1. 我们评估在NoC-level隔离和大量可用计算核心情况下新的OS设计的可能
1. 我们设计了操作系统原型M3。作为一个概念验证,我们实现了一个文件系统和管道。M3是开源https://github.com/TUD-OS/M3  最后,我们评估我们的原型的性能显示操作系统设计的可行性。支持异构核心交易系统利用和加速通过导航系统数据传输,M3优于Linux作为一个代表传统的OS五倍以上在某些应用程序级别的基准。
1. 性能评估，比传统的OS性能更好

# **方法**

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/I0jIbcR3eo5uCCx3MzScJbeKnEd.png)

1. 系统内核、服务与APP分别运行在不同的PE（是指各种计算资源）上
1. PE是否处于内核态是由DTU决定的，而非处理器的特权级模式决定的
1. DTU是PE与外界一切资源沟通的唯一接口，包括PE与其它PE，PE与内存之间
1. DTU将处理核心的异构性隐藏了，DTU支持消息传递和远程内存访问，DTU通过寄存器映射的方式绑定到核心上
1. DTU被用于进行核间隔离。运行APP的CPU核由于是自己运行在裸机之上，可能做任何事情，因此需要DTU提供强隔离机制

# 原型实现

Tomahawk由多个PE组成，通过一个片上网络和一个DRAM模块连接。PE是Xtensa RISC核心，没有特权模式，也没有MMU。此外，它们使用便签式存储器(SPM)而不是高速缓存作为唯一可直接寻址的存储器。

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/W2BZbcJFKoxkUAxFQjvc4iawnih.png)

在硬件方面，如图2所示，DTU由多个端点(EP)组成。每个端点都可以配置为发送端点、接收端点或存储端点。配置寄存器(缓冲区、目标、信用和标签)仅可由内核PE写入，而数据寄存器也可由应用PE写入。



# **实验**



# **结论**

# **未来与展望**

# **强相关参考论文**

|论文名称 |摘要/说明 |
|---|---|
|Tomahawk: Parallelism and Heterogeneity in Communications  Signal Processing MPSoCs |这是一个用于移动通信应用的多处理器片上系统(MPSoC)。Tomahawk由多个PE组成，通过一个片上网络和一个DRAM模块连接。PE是Xtensa RISC核心，没有特权模式，也没有MMU。此外，它们使用便签式存储器(SPM)而不是高速缓存作为唯一可直接寻址的存储器。 |
| | |
| | |
| | |
# 其它相关材料



