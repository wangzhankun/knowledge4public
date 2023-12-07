---
{"dg-publish":true,"permalink":"/体系结构与操作系统/RISC-V指令集相关/RISC-V 特权架构/","dgPassFrontmatter":true}
---


# RISC-V 特权架构

## RISC-V 特权架构 

之前我在科大学习过 RISC-V ，但内容基本集中于用户模式下的一般指令的应用，因此本人对特权指令几乎一无所知。但是若要实现一个 RISC-V 内核，那么必然要对这些东西烂熟于心，因此今天，我们就来学习一下 RISC-V 特权指令集吧。

|模式 |缩写 |编码 |
|---|---|---|
|机器模式 |M |11 |
|Hypervisor |H |10 |
|监管者模式 |S |01 |
|用户模式 |U |00 |
注：每一个特权级都有一组核心的特权 ISA 扩展，以及可选扩展和变种。支持的特权模式组合： **M**(Embedded without Protection)， **M+U**(Embedded with Protection)， **M+S+U (Unix-like OS capable)**, **M+H+S+U**

## 机器模式 

机器模式是 RISC-V 中 **hart (hardware thread 硬件线程)**可以执行的最高权限模式。在该模式下，hart 对内存、I/O 等所有必要的底层系统有着完全的使用权限。在几乎所有的基于 RISC-V 的嵌入式系统中，都对该模式进行了必要的实现与支持。

### 中断与异常 

以下内容参考了 [RISC-V 中文手册第十章 ](http://crva.ict.ac.cn/documents/RISC-V-Reader-Chinese-v2p1.pdf)和 [RISC-V privileged ISA Specification ](https://riscv.org/specifications/privileged-isa/)。

机器模式中，最重要的工作就是处理异常与中断。有以下几类异常、中断需要考虑：

* 访问错误异常 访问了无效或者没有权限访问的内存地址
* 断点中断 执行 `ebreak` 指令，或者地址、数据与调试触发器设置的断点匹配
* 环境调用中断 执行 `ecall` 指令
* 非法指令异常 译码阶段发现了无效的指令
* 非对齐指令异常 在有效地址不能被访问大小整除时发生

关于中断，有三种标准的中断源： **软件、时钟和外部来源**。

* 软件中断通过向内存映射寄存器中存数来触发，并通常用于由一个 hart 中断另一个 hart（在其他架构中称为处理器间中断机制）。
* 时钟中断：当实时计数器 `mtime` 大于 `hart` 的时间比较器（一个名为 `mtimecmp` 的内存映射寄存器）时，会触发。RISC-V 规定，在机器模式下，只有当 `mtimecmp` 寄存器被重新写入后， `mip` 寄存器中的时钟中断标志位才会被清除。因此，每次处理时钟中断，都不能忘记更新 `mtimecmp` 。

* 外部中断由平台级中断控制器（大多数外部设备连接到这个中断控制器）引发。不同的硬件平台具有不同的内存映射并且需要中断控制器的不同特性，因此用于发出和消除这些中断的机制因平台而异。所有 RISC-V 系统的共同问题是如何处理异常和屏蔽中断。

RISC-V 的机器模式还提供了各种令人眼花缭乱的 CSR 寄存器：

|寄存器 |简写 |描述 |
|---|---|---|
|Machine ISA Reg |misa |用于报告 hart 支持的 ISA 类型
具体内容见 [RISC-V privileged ISA Specification](https://riscv.org/specifications/privileged-isa/) |
|Machine Vendor ID Reg |mvendorid |用于提供实现该系统的制作商供应商等信息 |
|Machine Architecture ID Reg |marchid |指示了编码 hart 的基本微体系结构 |
|Machine Implementation ID Reg |mimpid |提供了处理器实现版本的唯一编码。 |
|Hart ID Reg |mhartid |指示了正在运行代码的硬件线程 ID |
|Machine Status Reg |mstatus |跟踪并控制 hart 当前的状态 |
|Machine Trap-Vector
Base-Address Reg |mtvec |存放了发生异常时处理器需要跳转到的地址，
即中断向量表，还有向量模式 |
|Machine Trap Delegation Reg |medeleg
mideleg |为提高性能，在 medeleg 和 mideleg 中提供单独的读/写位
以指示应由低特权级直接处理某些异常和中断。 |
|Machine Interrupt Reg |mip
mie |mip 指示了正在提交的中断
mie 包含了处理器能处理的和忽略的中断 |
|Machine Timer Reg |mtime
mtimecmp |内存映射寄存器 mtime 用于记录流逝的时间
mtimecmp 则用于时间的比较 |
|Counter-Enable Reg |mcounteren |控制了对低层特权级的硬件性能监视器的可用性 |
|Machine Scratch Reg |mscratch |暂时存放一个字大小的数据 |
|Machine Exception PC |mepc |指向发生异常的指令 |
|Machine Cause Reg |mcause |指示发生异常的种类 |
|Machine Trap Value Reg |mtval |保存了 trap 的附加信息:出错的地址、
非法指令本身，对于其他异常，其值为0。 |
幸好，我们需要重点关注的只有8个寄存器，如下：

* mtvec (Machine Trap Vector)
* mepc (Machine Exception PC)
* mcause (Machine Exception Cause)
* mie (Machine Interrupt Enable)
* mip (Machine Interrupt Pending)
* mtval (Machine Trap Value)
* mscratch (Machine Scratch)
* mstatus (Machine Status)

### CSR 寄存器 

#### `mstatus` 寄存器 

该寄存器在处理中断时会经常用到，且较为复杂，位域包含的信息较多，特在此专门介绍：

![](/img/user/体系结构与操作系统/RISC-V指令集相关/assets/UVKtbmxWOoqP7wxMATocqwqXndc.png)

注: WPRI: Write Preserve values, Reads Ignore values. 保留值
xIE: Interrupt Enable in x mode 中断使能
xPIE: Previous Interrupt Enable in x mode 之前的中断使能
xPP: Previous Privilege mode up to x mode 之前的特权级别

在中断使能方面， `MIE` 、 `SIE` 、 `UIE` 分别提供了 machine mode 、supervisor mode 、user mode 的全局中断使能位，若一个 hart 运行在特权级别 `x` 下，当 `xIE = 1` 时中断全局打开，反之则关闭。在 hart 于 `x` 运行时，无论 `wIE` 为何值，低权限中断 `w < x` 总是无效的，而无论 `yIE` 为何值，高权限中断 `y > x` 总是有效。

`MPIE` 和 `MPP` 分别存储了中断发生前的中断使能位和特权级别位。

类比于 `mstatus` 寄存器，较低权限的 `sstatus` 和 `ustatus` 寄存器也几乎同理，只不过少了一些东西而已。

#### `mip` 寄存器 

`mip` 寄存器指示了何种类型的中断正在传入 (pending)，与它相同功能的寄存器有 `sip` 和 `uip` 。

在该寄存器中，只有低特权级别的软件中断位 (USIP, SSIP)、时钟中断 (UTIP, STIP) 、外部中断 (UEIP, SEIP) 是可以通过 CSR 指令写入的，其他都是只读的。若有中断委托给了权限级别 `x` ，被委托的中断所对应的位（在 `xie` 和 `xip` 寄存器中）就可以使用了，否则，相应的位接地变 0 。

![](/img/user/体系结构与操作系统/RISC-V指令集相关/assets/GcX7b0nZOoOEFUxOAwecCgK4n9b.png)

xTIP: timer interrupt-pending bit in x mode 时钟中断
xSIP: software interrupts in x mode 软件中断
xEIP: external interrupt 外部中断

因为今后工作的需要，请注意， `MTIP` 、 `STIP` 、 `UTIP` 位分别对应机器模式、监管者模式、用户模式的时钟中断信号。 `MTIP` 位是只读的，而 `UTIP` 和 `STIP` 位在机器模式下可以写入，这就是将时钟中断处理下放给低级权限的方式。

#### `mie` 寄存器 

`mie` 寄存器包含了相应的中断使能位， `sie` 和 `uie` 功能相似。注意观察 `mcause` 寄存器编码 ，可以发现， **若 bit**`**i**`**在**`**mie**`**和**`**mip**`**寄存器都置位，且全局中断位打开，那么中断**`**i**`**就会视作发生，并被处理。**一般情况下，在低权限运行时，机器模式的中断一直有效。

![](/img/user/体系结构与操作系统/RISC-V指令集相关/assets/EzL5bdJIxotcqBxUgUncgWyJnNh.png)

xTIE: timer interrupt-enable bit in x mode 时钟中断使能位
xSIE: software interrupt-enable in x mode 软件中断使能位
xEIE: external interrupt-enable in x mode 外部中断使能位

#### `mcause` 寄存器 

`mcause` 寄存器的作用是记录中断/异常事件的类型/起因。在当 trap 进入机器模式后，将异常/中断事件产生的起因（或者称之为谁导致了异常/中断事件）写入到该寄存器中。

![](/img/user/体系结构与操作系统/RISC-V指令集相关/assets/Rq3xbEN6xo8TilxN3jlc4CO5nle.png)

mcause 寄存器编码形式，首位为 1 时是中断，0 时为异常

![](/img/user/体系结构与操作系统/RISC-V指令集相关/assets/AxeLburarokZ6lxRQ9jcJks2njd.png)

mcause 寄存器对应事件表

上表详细记录了各个中断/异常事件的代码编号，我们以后会经常用到。大家仔细观察 mcause 寄存器对应事件表 和 mie 寄存器位编码图 、 mip 寄存器位编码图 ，会发现 `mcause` 中编码的事件号的数字，正巧就等于 `mie` 、 `mip` 中对应事件的位偏移量。这一巧妙的设计在今后可能会带来意想不到的方便！

还有一点就是，当一个指令遇到了多个异常时（这条指令是多么的不幸啊），那么处理异常的优先级也是不一样的，下表很详细的列出了它们的优先级关系：

![](/img/user/体系结构与操作系统/RISC-V指令集相关/assets/OjadbMebzo5CHhxk1NLc0X8wndd.png)

#### `mtvec` 寄存器 

该寄存器全名 Machine Trap-Vector Base-Address Register，它存放了 trap vector 的信息，包括了基地址和模式 Mode 。基地址要求必须 4 字节对齐，即确保末两位为 0 。当中断/异常发生时，PC 值肯定需要跳转到中断/异常处理程序，该寄存器就保存了这些处理程序的地址。该寄存器有两种使用方法，直接寻址和间接寻址。

![](/img/user/体系结构与操作系统/RISC-V指令集相关/assets/XzDhb2HMzoRLC3xgqLuc1x4Bn0f.png)

直接寻址时，Mode = 0 ，所有转到机器模式下的 traps 都会将基地址值赋给 PC ；间接寻址时，Mode = 1 ，所有转到机器模式的 **同步异常**会把基地址传给 PC，而遇到中断时，会根据中断的编号形成特定的偏移量，加上基地址后再赋给 PC ，事实上，中断程序的处理程序地址就是以数组的形式存放在 `mtvec` 部分了。例如，如果一个机器模式的时钟中断产生了，那么 PC 会被设置为 BASE + 7 * 4 = BASE + 0x1c 。

---

好，了解了 `mstatus` 以及 `mip` 、 `mie` 、 `mcause` 后，我们明白：

* 处理器在机器模式下运行，在全局中断使能位 `mstatus.MIE` 置 1 时才会产生中断。
* 每个中断在控制状态寄存器 `mie` 以及 `mip` 中都有自己的使能位。

例如，将所有三个控制状态寄存器合在一起考虑，如果 `mstatus.MIE=1` ， `mie[7]=1` ，且 `mip[7]=1` ，则 CPU 就会开始处理机器模式的时钟中断。

一般来说，发生中断/异常时，机器会：

* 对于中断，将目前的 PC 保存到 `mepc` 中，新 PC 从 `mtvec` 中取出。对于异常， `mepc` 保存了指向异常的指令
* 根据异常的类型及来源，设置 `mcause` ，并对 mtval 进行相应设置
* `mstatus` 中的 `MIE` 位置 0 ，禁止中断，并把先前的 `MIE` 值保存到 `MPIE` (Machine Previous Interrupt Enable) 中。
* 发生异常之前的权限模式保存在 `mstatus` 的 `MPP` 域中，再把权限模式改为 M

### 中断嵌套 

有时需要在处理 异常/中断 的过程中，会需要转到处理更高优先级的中断。然而任何体系结构都不可能有这么多资源去满足近乎无限的中断嵌套。 `mepc` `mcause` ， `mtval` 和 `mstatus` 这些控制寄存器都只有一个，因此，如果第二个中断到来，就需要软件的帮助，否则这些寄存器中的旧值会被破坏，导致数据丢失。 **可抢占的中断处理程序可以在启用中断之前把这些寄存器保存到内存中的栈，然后在退出之前,禁用中断并从栈中恢复寄存器。**

除了上面介绍的 `mret` 指令之外，机器模式还提供了另外一条指令：wfi (Wait For Interrupt)。wfi 通知处理器目前没有任何有用的工作，所以它应该进入低功耗模式，直到任何使能有效的中断等待处理，即 `mie&mip ≠ 0` 时。对该指令的实现，RISC-V 处理器有多种方式：中断待处理之前都停止时钟；有的时候只把这条指令当作 `nop` 来执 行。因此，wfi 通常在循环内使用。

### 物理内存保护 

在机器模式下，我们可以自由地访问各种硬件平台。然而，一旦我们将这些艰巨的任务转给用户，他们可能会毁了一切。我们需要一种可靠的机制，保护系统免受不可信代码的危害，为不受信任的进程提供隔离保护。以下内容参考了 [RISC-V 中文手册第十章 ](http://crva.ict.ac.cn/documents/RISC-V-Reader-Chinese-v2p1.pdf)和 [RISC-V privileged ISA Specification ](https://riscv.org/specifications/privileged-isa/)。

在硬件设计里，PMP (Phsical Memory Protection) 是可选项，但在大部分地方我们都可以见到它的身影。PMP 检查一般用于 hart 在监管者模式或用户模式下的所有访问；或者在 `mstatus.MPRV = 1` 时的 load 和 store 等情况。一旦触发 PMP 保护，RISC-V 要求产生精确中断并处理。

PMP 允许机器模式指定用户模式下可以访问的内存地址。PMP entry 由一个 8-bit 的 PMP 配置寄存器和一个 32/64 位长的 PMP 地址寄存器组成。整个 PMP 包括若干个（通常为 8 到 16 组）PMP entry 。配置寄存器可以配置读、写和执行权限，地址寄存器用来划定界限。

下两图显示了 PMP 地址寄存器和配置寄存器的布局。pmpxxcfg 表示了 PMP 配置寄存器，pmpxxaddr 表示了 PMP 地址寄存器。



![](/img/user/体系结构与操作系统/RISC-V指令集相关/assets/SnlBbtmujo37TGxE3P0candTnZH.png)





![](/img/user/体系结构与操作系统/RISC-V指令集相关/assets/RUTbbD9JyozNFDxglzScUhztnrE.png)



当处于用户模式的处理器尝试 load 或 store 操作时，将地址和所有的 PMP 地址寄存器比较。如果地 址大于等于 PMP 地址 i，但小于 PMP 地址 i+1，则 PMP i+1 的配置寄存器决定该访问是否可以继续，如果不能将会引发访问异常。

R，W，X 位分别指示了 PMP 入口允许读、写、执行权限。A 域解释了 PMP 寄存器的编码情况。



![](/img/user/体系结构与操作系统/RISC-V指令集相关/assets/CoOEbEfZGoC2QPxBgDic0iCEnLT.png)



![](/img/user/体系结构与操作系统/RISC-V指令集相关/assets/V5MNbB4dMocRkMxmhnIcubpln4f.png)

## 监管者模式 

前文所述， `mstatus` 、 `mie` 、 `mip` 、 `mtvec` 等寄存器在监管者模式 (Supervisor mode) 下都有与之名字几乎一样的、功能也相似的寄存器，方便了我们举一反三，这就体现出 RISC-V 体系结构的优越性了。在这里先挖个坑，有时间我会专门介绍一下 RISC-V 体系结构的优越性。

相比于机器模式的最高权限和强制手段，监管者模式没有这么高的权限。一般来说，监管者模式就是为对标现代操作系统而生的。监管者模式通常存在于复杂的 RISC-V 系统上，其核心功能就是支持内存分页、内存保护、中断/异常处理等。当然，监管者模式还是有些地方与机器模式不同，接下来我会重点介绍。

### SATP 寄存器 

顾名思义，satp (Supervisor Address Translation and Protection Register) 寄存器的作用是在监管者模式下，控制地址转换与保护的。寄存器内位分布如下图：

![](/img/user/体系结构与操作系统/RISC-V指令集相关/assets/LOKYbOXPIoLfEexJirQci4ugnzg.png)

注：PPN: Physical Page Number of the root page table.
ASID: Address Space Identifier

ASID (地址空间标识符) 域是可选的，它用于帮助地址空间的转换，降低上下文切换的开销。PPN 存储了根页表的物理页号，以 4 KiB 页面大小为单位，它在内存分页中起了十分重要的作用。MODE 位用于选择地址转换的方式，详见 `SFENCE.VMA` 指令。

MODE 位的功能见下表：

![](/img/user/体系结构与操作系统/RISC-V指令集相关/assets/VdlVbWzveoynK7xoZogcFR2Vnyh.png)

### 内存分页 

在稍微复杂的 RISC-V 处理器中，仅仅依靠 PMP 模块来提供内存保护是不够的。因为 PMP 不够灵活：仅支持固定数量的内存区域；很多复杂的应用程序要求在物理存储中连续，会产生存储碎片；PMP 又无法有效支持分页。

因此，设计人员在监管者模式中又发明了基于页面的虚拟内存机制（分页机制），可以说，分页机制是操作系统的核心问题了，对于分页机制，详细介绍请见 [分页机制 ](https://www.jianshu.com/p/3558942fe14f)，这里做简单说明，RISC-V 中监管者模式提供了一种传统的虚拟内存系统，它将内存划分为 **固定大小的页**，以此为基础进行地址转换，并提供对内存内容的保护。启用分页的时候，监管者模式和用户模式下的地址（包括 load 和 store 的有效地址和 PC 中的地址）都是 **虚拟地址**，要访问物理内存,它们必须被转换为真正的 **物理地址**。

参照 `satp` 寄存器的MODE 功能表 ，在 MODE = bare 时，没有分页机制，此时虚拟地址就等于物理地址，此时也就没有额外的内存保护功能了。RV32 只支持 Sv32 分页模式，RV64 支持 Sv39、Sv48、 *Sv57、Sv64*分页，粗略看一下 [RISC-V privileged ISA Specification ](https://riscv.org/specifications/privileged-isa/)，RV64 居然已经在为四级分页作准备了！

当 satp 启动分页时，在监管者模式或用户模式下，虚拟地址 (VA) 会将 satp 寄存器中根页表地址作为基址 (base)，以及自身的页号作偏移 (VPN[1])，在页表中通过计算偏移位置 (base + VPN[1] * 4) 找到 **页表项 (Page Table Entry PTE)**。如果该 PTE 不是叶 PTE（什么是页 PTE 下面会解释），那么再将刚刚找到的 PTE 作为基址，用虚拟地址携带的第二个页号作偏移，继续算出第二个页表项，直到获得物理地址 (PA)，更加详细的虚拟地址转换过程见 附录 。

![](/img/user/体系结构与操作系统/RISC-V指令集相关/assets/SuOdbK0WMoomTuxNayUcld20ntc.png)

再来看看虚拟地址和物理地址的二进制格式。我们以 Sv32 分页模式为例，虚拟地址、物理地址的编码都是将页号放在 MSB 处，而将偏移量放在 LSB 处。Sv32 分页支持两级分页。从偏移量位长可以看出，Sv32 页表含有 1024 个 PTEs，每个页表项占 4 字节，总共 4 KiB 。

![](/img/user/体系结构与操作系统/RISC-V指令集相关/assets/K205blSEFoSbZOxExegcg4EQnyh.png)

最后看一下页表项。 **V**alid 位指示该 PTE 是否有效； **R**eadable， **W**riteable，e **X**ecutable 指示了该页是否可读、可写、可运行，当这三位都是 0 时，表明该 PTE 指向了下一层页表，其为 **非叶 PTE**，否则就是 **叶 PTE**； **U**ser 位指示了该页是否可以被用户模式访问； **G**lobal 指示了全局映射，存在于所有的地址空间中； **A**ccess 位指示了该页最近是否被读、写、取； **D**irty 位指示了虚拟页最近是否被写过。对于非叶 PTE， **D**， **A**， **U**位被保留，并被清零。RSW 是保留的，用于操作系统软件。

![](/img/user/体系结构与操作系统/RISC-V指令集相关/assets/PfmkbA7CdoWheDxehHLczTxsnNh.png)

![](/img/user/体系结构与操作系统/RISC-V指令集相关/assets/UWd1bSGkeovBjlx0qJXcgWztnLg.png)

---

**分页**指的就是用 地址管理器或者地址翻译器 （下统称 MMU）将系统中的物理地址转换/翻译为虚拟地址。我们已经详细地介绍了 翻译过程 ，该过程使用 `satp` 寄存器对虚拟地址进行一系列的访问计算，得到物理地址。接下来，我们讨论一下页表与 **页错误 (page fault)**。

考虑在 Sv32 分页模式下，一个页表最多需要 `1024 * 4 bytes = 4 KiB` ，而二级分页需要 1024 个页表，此外页表的页表（页目录）也需要 4 KiB，因此，整个页表就需要 4 MiB 大小。而在 Sv39 等三级分页甚至四级分页中，页表需要的空间会更多，因此毫无疑问的，页表不能存在于一级 Cache 中。我们可以将页表放在内存中的任何位置，并以 4 KiB 对齐。

RISC-V 设计分页机制时充分了解并吸取了早期体系结构的设计教训。 [x86-64 分页 ](https://wiki.osdev.org/Paging)中上层页表控制了下层页表，如果上层页表是只读的，那么被该页表控制的下层页表就不能被写入了，这可不是什么聪明的做法。而 x86-64 可以做到 [粗粒度控制与细粒度控制的转换 ](https://www.sandpile.org/x86/paging.htm)，却是一个巧妙的做法。 RISC-V 设计人员引入了叶 PTE 与非叶 PTE 的概念，并使用 R W X 这三个位域来定义 ，从而将 页表的层级 (level) 和它是指向页表还是仅包含物理地址区分 开来，使得每个层级的 PTE 都可以是叶 PTE，既实现了粗细粒度控制，又可以防止上层页表控制下层页表。例如，在 Sv39 中，若第二级页表就是叶 PTE，那么就会形成一个大小为 2 M 的 **超级页**，相比于 4 KB 更粗粒度。

MMU 会在以下几种情况下发出页错误信号：

* 在取指令时，发现指令所在的页没有运行权限 X，或者该页无效 V，此时异常代码为 12 。
* 取数据时，发现数据所在的页没有读权限 R，或在该页无效 V，此时异常代码为 13 。
* 存储数据时，发现数据所在的页没有写权限 W，或在该页无效 V，此时异常代码为 15 。

在多数操作系统中，他们认为的正确应对方式是杀掉出现问题的进程（解决提出问题的人🐶），但如果使用了 `copy-on-write` 技术，那么这可能是个 feature（不是 bug 是个 feature 🐶）。

### `SFENCE.VMA` 与同步 

在内存分页中，我们看到为了从虚拟地址得到一个物理地址，我们经过了相当复杂的计算过程。考虑到页表都是存放在内存或者高级 Cache 里，多次访问页表会导致访问性能大大降低。从本科的操作系统课程中可以了解到，解决这一问题的通常作法是引入 TLB（Translation Lookaside Buffer 地址转换缓存），而这又会到来页表相不一致的问题。在 RISC-V 中，解决方法就是增加一条指令，用于刷新 TLB，进行显式同步。

该指令叫内存管理栅栏指令 (fence instruction) `SFENCE.VMA` 。它的作用是 **同步**。该指令更新在内存中的“内存管理数据结构”（嗨，其实就是页表），确保在这条指令之前的存储操作都是有序的。该指令也可以用于刷新一些与地址转换相关的局部 cache（就是 TLB）。

该指令需要两个可选的参数 `rs1` 和 `rs2` ，这样可以缩小缓存刷新的范围。 `rs1` 针对页表，指示了页表哪个虚址对应的转换被修改了； `rs2` 给出了被修改页表的进程的地址空间标识符 (ASID)。如果两者都是 `x0` ，便会刷新整个 TLB。

说了这么多，我们到底要在什么场合用到它呢？ [RISC-V privileged ISA Specification ](https://riscv.org/specifications/privileged-isa/)给出了如下五个场景，这里仅做简单介绍。

* 当一个软件要回收再利用一个 ASID（与另一个页表关联）
* 若具体实现没有提供 ASID，或者软件选择 ASID = 0，那么 `satp` 寄存器每次被写入后，就应当使用 `SFENCE.VMA with rs1=x0` 指令。
* 若软件修改了非叶 PTE ，应该执行 `SFENCE.VMA with rs1=x0` 。
* 若软件修改了叶 PTE，应该执行 `SFENCE.VMA with rs1=VA within the page` 。
* 特殊情况如给叶 PTE 增加权限、将无效 PTE 变为有效等，软件可能会选择执行 `SFENCE.VMA` 。

### 中断与异常委托 

一般情况下，在系统发生异常时，控制权都会被移交到 **机器模式**下的 trap 处理程序中。然而，Unix 等系统的大多数 trap 处理程序都 **应该在监管者模式下**运行。一个简单的解决方案是，让机器模式下的处理程序指向监管者模式的处理程序。但这样的坏处显而易见：速度过慢，明明可以一步到位地转向监管者模式，非要绕道机器模式然后再到监管者模式。因此，RISC-V 提供了一种委托机制，将一些中断/异常处理程序委托给监管者模式。

CSR 寄存器 `mideleg` (Machine Interrupt Delegation，机器中断委托) 指示哪些 **中断**将委托给监管者模式。与 `mip` 和 `mie` 一样，被委托的中断位域位置与该中断在 mcause 寄存器的事件编码图 的代码号一致。

例如， `mideleg[5]` 对应于监管者模式的时钟中断，如果把它为 1 ，即 `li a0, 1 << 5 ; csrw mideleg a0` ， 监管者模式的时钟中断将由该模式下的异常处理程序，而不是机器模式的异常处理程序处理。当然，委托意味着对中断的一种负责，因此委托给监管者模式的任何中断都会受到监管者模式下 CSR 寄存器（主要是 `sie` 、 `sip` ）的控制，而没有被委托的中断对应位是无效的。

相应地， `medeleg` 寄存器处理的是 **同步异常**委托，其用法与 `mideleg` 寄存器相通，被委托的异常位域位置与该异常在 mcause 寄存器的事件编码图 的代码号一致。例如，当 `medeleg[15]` 设置为 1 时，那么 store 过程中的页错误 (page fault) 就会委托给监管者模式。

在 hart 运行的权限级别低于或等于被委托的级别时，此时若 bit `i` 在 `mideleg` 置位，且 `mstatus.SIE` 或 `mstatus.UIE` 中断有效时，中断会被认为是全局有效的。

---

可能有人会问，那么，委托这种情况只会发生在监管者模式下么？ **当然不会**。如果这个系统支持在用户模式下处理 trap ，那么监管者模式的 `sedeleg` 和 `sideleg` 寄存器就会开始委托机制：若产生的 trap 可以被委托给用户模式，那么该 trap 会转移给用户模式下的处理程序，而不是监管者模式下的处理程序。

---

中断委托的具体过程如何？

* 某个 trap 被委托给了模式 `x` ，并且在执行过程中触发
* `xcause` 寄存器更新，写入 trap 的起因
* `xepc` 寄存器更新，写入 trap 发生时指令的地址（虚拟地址）
* `xtval` 寄存器更新，写入 trap 对应的处理程序位置
* `mstatus.xPP` 写入在发生 trap 时的特权级别
* `mstatus.xPIE` 写入 `xIE` 的值，而 `xIE` 的值被清除
* **注意：**`**mcause**`**和**`**mepc**`**以及 MPP MPIE 域不会更新**

trap 永远不会从特权较高的模式过渡到特权较低的模式。例如，如果机器模式下，非法指令异常已经被委托给监管者模式，而此时在机器模式下，软件执行了一条非法指令，则 trap 将采用机器模式的处理程序，而不是委派给监管者模式。然而，还是上面的例子，如果监管者模式下，软件遇到了非法指令异常，trap 由监管者模式的异常处理程序处理。

---

有些异常无法被权限较低的模式处理，此时相应的委托寄存器的位域就必须接地。

## 附录 

为了给以后的工作打下坚实的基础，这里详细翻译一下 [RISC-V privileged ISA Specification ](https://riscv.org/specifications/privileged-isa/)中 4.3.2 节，关于虚拟地址的翻译/转换过程：

1. 定义 `a` = satp. *ppn*× PAGESIZE ，且定义 `i` = LEVELS − 1 。
1. 定义 `pte` 指向地址为 `a` +va. *vpn*[ `i` ]×PTESIZE 的 PTE 的指针，并访问。若访问 `pte` 违反了 PMP (Physical Memory Protection) 或 PMA (Physical Memory Attributes) ，相应的访问异常会产生。
1. 如果 `pte.v = 0` , or `pte.r = 0` and `pte.w = 1` ，停止并产生相应的页错误。
1. 否则，PTE 有效，若 `pte.r = 1` or `pte.x = 1` 跳转到第 5 步。否则，该 PTE 就是指向另一个页表的 PTE，令 `i` = `i` -1 。若 `i < 0` ，停止并产生页错误。否则，令 `a` = pte. *ppn*× PAGESIZE ，跳转到第 2 步。
1. 叶 PTE 找到了，根据 `pte.r` 、 `pte.w` 、 `pte.x` 、 `pte.u` 位的值，确定它是否有权限，若没有，那么停止并产生相应的页错误。
1. 若 `i > 0` 且 `pte.pnn[i-1:0] != 0` ，这是一个非对齐的超级页；停止并产生相应的页错误。
1. 若 `pte.a = 0` ，或者内存访问为 store 且 `pte.d = 0` ，要么产生页错误，要么
1. 此时转换成功，生成物理地址：
