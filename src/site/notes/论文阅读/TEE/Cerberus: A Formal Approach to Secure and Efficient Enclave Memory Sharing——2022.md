---
{"dg-publish":true,"permalink":"/论文阅读/TEE/Cerberus: A Formal Approach to Secure and Efficient Enclave Memory Sharing——2022/","dgPassFrontmatter":true}
---


# Cerberus: A Formal Approach to Secure and Efficient Enclave Memory Sharing——2022

先看Elasticlave: An Efficient Memory Model for Enclaves，再读这篇论文

# **摘要**

硬件飞地依赖于不相交的内存模型，该模型将每个物理地址映射到一个飞地以实现强大的内存隔离。然而，这严重限制了Enclave程序的性能和可编程性。虽然之前的一些工作提出了Enclave内存共享，但它并没有提供正式的模型或对其设计进行验证。本文提出了一种安全高效的Enclave内存共享的形式化方法Cerberus。为了减少形式化验证的负担，我们比较了不同的共享模型，选择了一种简单但功能强大的共享模型。在共享模型的基础上，Cerberus扩展了Enclave平台，使得Enclave内存可以通过额外的操作在多个Enclave之间不可变和共享。我们使用增量验证，从称为可信抽象平台(TAP)的现有正式模型开始。使用我们的扩展TAP模型，我们正式验证了Cerberus不会破坏或削弱飞地的安全保证，尽管允许内存共享。更具体地说，我们证明了形式模型上的安全远程执行(SRE)属性。最后，通过在现有的Enclave平台RISC-V Keystone上实现Cerberus，说明了Cerberus的可行性。

# **论文研究目标**

## **问题**

1. Enclave每次启动时都需要经历昂贵的初始化，因为Enclave程序不能使用系统中的共享库，也不能从现有进程克隆[38]。每次初始化包括将Enclave程序复制到Enclave存储器中，并执行测量以标记程序的初始状态。根据程序和初始数据的大小，初始化延迟按比例增加。
1. 程序员需要意识到关于内存的非传统假设。例如，像fork或克隆这样的系统调用不再依赖高效的写入时复制内存，从而导致性能显著下降。



## 贡献

1. 提供具有内存共享的通用正式Enclave平台模型，该模型削弱了不相交的内存假设并适配多种Enclave平台
1. 通过自动形式验证正式验证修改后的Enclave平台模型满足SRE属性
1. 提供可与现有系统调用一起使用的可编程接口函数
1. 在现有Enclave平台上实施扩展并演示Cerberus缩短了Enclave创建延迟

# **方法**

## 形式化验证背景知识

### Secure Remote Execution Property (SRE)

1. 对远程平台上的飞地的测量可以保证飞地被正确设置并以确定性的方式运行
1. 每个飞地程序都受到完整性保护，不受不可信实体的影响，因此可以确定地执行
1. 每个飞地程序都是受机密性保护的，以避免向不可信任实体泄露机密。

### Trusted Abstract Platform model (TAP)

详细参考 论文 A Formal Foundation for Secure Remote Execution of Enclaves

## Design decisions

### Writable shared memory

Cerberus只设计了只读的共享内存空间。

Cerberus不支持基于IPC或其他可变共享数据的用例。类似地，PIE[38]也只允许在飞地之间共享只读内存。

### Memory sharing model

* No sharing： enclave之间不共享任何空间
* Arbitrary sharing：enclave之间可以随意共享内存空间
* Capped sharing：每个enclave可以只能访问一定数量的共享物理内存
* Single sharing：每个enclave只能访问一个共享物理内存

# **实验**

# **结论**

# **未来与展望**

# **强相关参考论文**

|论文名称 |摘要/说明 |
|---|---|
|A Formal Foundation for Secure Remote Execution of Enclaves | |
|Elasticlave: An Efficient Memory Model for Enclaves | |
| | |
| | |
# 其它相关材料

* 开源实现 https://github.com/cerberus-ccs22/TAPC
