---
{"dg-publish":true,"tags":["论文","TEE"],"permalink":"/论文阅读/TEE/Elasticlave An Efficient Memory Model for Enclaves/","dgPassFrontmatter":true}
---


# Elasticlave: An Efficient Memory Model for Enclaves——2022

# **摘要**

现有的TEE内存模型是僵化的-它们不允许一块飞地与其他飞地共享内存。

我们提出了一种新的允许共享的TEE内存模型ELASTICLAVE。ELASTICLAVE在管理访问权限方面在安全性和灵活性之间取得了平衡。

# **论文研究目标**

## **问题**

如果我们想要支持空间隔离内存（spatial isolation model，这个是作者提出的概念，认为现在的很多TEE都是这种模型）上的Enclave之间的内存共享，我们需要额外的可信协调器Enclaves以及加密的安全消息传递通道。如果没有这些额外的机制，实现安全的共享内存在管理共享区域的所有权和访问权限方面充满挑战，如权限重新委派（permission re-delegation）[26]、混淆代理(confused deputy)[28]、恶意竞争(malicious race)[14]和TOCTOU攻击[25]等攻击载体所表明的那样。

再spatial isolation model 的TEE上面可以通过可信协调器和加密信道实现ELASTICLAVE，但是这种开销非常大。

商用处理器上可用的大多数TEE遵循一种内存模型，我们称之为空间隔离模型[16，19，19，21，35，40，50，57]。在该模型中，每个飞地具有两种不同类型的非重叠虚拟内存区：(A)私有内存是飞地本身所独有的，并且不能被操作系统和在系统上运行的所有其他飞地访问；(B)公共存储器对于飞地和可能与其他飞地共享它的不可信的OS是完全可访问的。

## 贡献

作者提出了一种新的TEE内存模型ELASTICLAVE（与传统的spatial isolation model有很大不同），以支持共享内存。

我们提出了一种新的内存模型ELASTICLAVE，它允许飞地之间和操作系统之间共享内存，具有比空间隔离更灵活的权限。在允许灵活性的同时，ELASTICLAVE不做任何简单化的安全假设或降低其对空间隔离模型的安全保证。在这项工作中，我们将Enclaves视为对应用程序进行分区的基本抽象，因此假设Enclaves彼此不信任，并且可能在其生命周期内受到威胁。ElasTICLAVE在灵活性和安全性之间取得了平衡。分区应用程序中的每个飞地都有其各自的内存权限视图。

# 问题描述

## 内存共享中存在的问题

enclave之间进行内存共享时必须要进行权限管理。

1. 静态权限。

允许enclave同时访问共享区域。在开始执行时，enclave就为共享区域设置了足够的权限。然而如果enclave2在某时被破坏了，它可以在e1执行其自己的操作时观察或篡改r（r是enclaves的读写序列）的中间状态。在此设计中，e1和e2都不能更改其自身或其他飞地的权限。

1. 所有权转移。

当enclave要对共享区域进行操作时，就需要获得对其的独占拥有权。但是，被破坏的enclave可能会把所有权转交给其它被破坏的enclave，拒绝交还所有权。此外，这种设计不允许并发操作。

1. 动态权限。

这种设计允许拥有共享内存的enclave对其它enclave进行动态地授权或者撤销授权。但是也会有被攻击的风险。例如，尽管e2可以在开始自己的写入操作之前检查e1是否已撤销其权限，但当e2处于写入操作过程中时，e1可以重新获得读/写权限并干扰e2的操作。通过这种方式，有问题的所有者飞地可以利用不一致的权限视图来发起恶意TOCTOU攻击。

1. 所有权转移与动态权限。

这样，非所有者飞地可以获得临时所有权，以可靠地控制权限，而不会受到所有者飞地的排挤。在我们的示例中，e2获得临时所有权以执行读或写操作。由于E1不再是所有者，因此它不能更改自己的权限来发起恶意TOCTOU攻击。这种动态性带来了复杂性--当前所有者仍然可以随时更改权限，这使得安全决策变得困难。在同时访问的情况下，只有一个飞地可以是所有者，例如e2。另一块Enclave，即e1，可以获取当前视图并做出安全决策以启动操作。但是，临时所有者e2可以在这样的操作过程中更改权限以攻击e1。因此，增加的复杂性并不能提高对抗恶意竞争的安全性。

## 问题形式化描述

两个安全属性：

1. Bounded Escalation

If an owner does not explicitly authorize an enclave e to access a region r with a said permission, e will not be able to make that access.”

1. Enforceable Serialization of Non-faulty Enclave

如果app预先定义了non-faulty enclave的访问序列，那么enclave必须按照这个序列进行访问否则就会被终止。假定若干个enclave对一个共享内存的访问序列为$a_1,a_2,a_3,...a_n$，那么app的作者就需要保证所有的访问都遵循这个序列，即使存在其它的faulty enclave。

# ELASTICLAVE设计

与enclave进行交互的三种抽象：

1. 每一个enclave都独立地拥有对共享内存地异步权限视图（asymmetric permission views）
1. 只要没有超过预先设立地最大值，就可以动态调整权限
1. 获得共享内存的独占权并可以原子地转移给其它enclave

一个ELASTICLAVE内存区域有四种权限：read, write, execute, lock。

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/boxcnOqBeQ1kS84tBnlwuCuhFqh.png)

每个区域都可以用在全局命名空间中唯一标识它的通用标识符来寻址，并且可以映射到不同飞地中的不同虚拟地址。

## 权限检查

ELASTICLAVE执行两类安全检查：(1)对所请求的资源(例如，内存区域和飞地)进行可用性检查，以确保指令不会在不存在的资源上操作；以及(2)对调用方进行权限检查，以确保其对所请求的指令具有足够的特权。

## acquire/release lock

我看不懂，但我大受震撼。我不理解这个跟所有权转移有啥区别？前文中提到的所有权转移面临的问题难道锁的转移就不存在了吗？

访问者可以尝试使用CHANGE指令获取或释放锁。它返回访问者修改的权限，包括指示获取/释放是否成功的lock位。ELASTICLAVE确保在任何情况下，只有一块飞地持有锁。如果任何其他飞地访问该地区或试图发布关于该地区权限的更改指令，这些请求将被拒绝。

锁持有者可以使用CHANGE指令来释放锁。然而，在某些情况下，锁持者希望明确规定它打算让哪个飞地成为该锁的下一个锁持者。ELASTICLAVE允许锁持有者调用指定下一个所需访问者的飞地ID的transfer指令。下一个锁持有者必须将内存区域映射到其地址空间中，才能成功transfer。成功的transfer指令将清除源飞地许可中的lock位，并自动设置目标飞地的lock位。共享内存区的其他权限位和虚拟地址映射保持不变。

## 异常与信号

“First, when the owner destroys a memory region r,E LASTICLAVE will invalidate permissions granted to other enclaves since the memory region no longer exists. To prevent enclaves from continuing without being aware that the memory region can no longer be accessed, ELASTICLAVE will send signals to notify all accessors who had an active mapping (i.e., mapped and not yet unmapped) for the destroyed memory region. The second usage of signals is to notify changes on lock bits. Each time an accessor successfully acquires or releases the lock (i.e., using change or transfer instructions), ELASTICLAVE issues a signal to the owner. The owner can choose to mask such signals or to actively monitor the lock transfers. When a transfer succeeds, ELASTICLAVE notifies the new accessor via a signal.” (Yu 等, 2022, p. 7) 首先，当所有者销毁内存区域r时，E LASTICLAVE将使授予其他飞地的权限无效，因为该内存区域不再存在。为了防止Enclaves在不知道内存区域不能再被访问的情况下继续范文，ELASTICLAVE将发送信号来通知依然映射该内存区域的所有访问者。信号的第二个用法是通知lock位的变化。每次访问者成功获取或释放锁(即使用CHANGE或TRANSPORT指令)时，ELASTICLAVE都会向所有者发出信号。拥有者可以选择屏蔽此类信号或主动监视锁定传输。当传输成功时，ELASTICLAVE通过信号通知新的访问者。

## 接口的使用

接口使用标识符(EID和UID)唯一地标识飞地和内存区域，我们将其实现为非重复的整数值。我们保留特殊的EID1来标识不受信任的代码。Enclaves可以使用证明和安全通道交换EID和UID。

## 安全性属性的保证

前文提到了两个安全属性：Bounded escalation和Enforceable Serialization of Non-faulty Enclave，那么我们的设计是如何保证的呢？

### Bounded escalation

1. 只有所有者才能够使用create改变允许访问共享内存的enclave集合。非所有者不能够向其它enclave授权访问。
1. 每个合法的enclave最多拥有只有所有者授权的那些权限，所有者默认拥有最高权限
1. 每一次的访问以及ELASTICLAVE指令的执行都会进行权限检查

### 访问序列化

1. 对于enclave的某次在预定义的访问序列中的访问$e(a_i)$而言，访问者会获取lock并禁止其它访问者打扰
1. 当访问者改变时，当前的enclave可以通过transfer指令正确的转移到预定义访问序列中的下一次访问

# 实现

作者基于keystone实现了原型设计，见后文相关材料。

在每次PMP更新后，m模式软件需要使用RISC-V中的sfence.vma指令，以防止硬件使用过时的PMP配置。RISC-V[9]的RocketChip实现就是一个例子，它将PMP查找结果缓存到TLB中。在这种情况下，sfence.vma执行TLB刷新以使PMP查找结果保持最新。感兴趣的读者可以参考RISC-V标准规范。

安全监控器将关于存储器区域、飞地、静态最大值和权限的所有元数据存储在m模式存储器中，该存储器由一个保留的PMP条目保护。

当Enclave调用ELASTICLAVE指令时，执行陷入m模式。S模式或U模式软件不能更改此控制流。在检查Enclave是指令的允许调用者(表2)之后，s模式执行所请求的操作，并在必要时更新元数据和PMP。

ELASTICLAVE在其实现中保持三个映射：(A)到每个飞地中相应映射的UID的虚拟地址范围；(B)UID和相应的权限元数据(包括每个飞地和所有权中的权限和静态最大权限)；以及(C)每个UID映射到的有效物理地址范围。因此，当Enclave尝试访问虚拟地址时，ELASTICLAVE执行两级转换：从虚拟地址到UID，然后到物理地址。权限检查是通过查找与UID绑定的权限元数据来执行的。映射和取消映射指令仅更新映射(A)。转移和更改指令更新映射(B)。共享和创建指令更新映射(B)和(C)。Destroy指令从所有三个映射中删除与提供的uid绑定的数据。

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

* 开源实现 https://github.com/jasonyu1996/elasticlave
* Appendix https://www.usenix.org/system/files/usenixsecurity22-yu-jason.pdf
