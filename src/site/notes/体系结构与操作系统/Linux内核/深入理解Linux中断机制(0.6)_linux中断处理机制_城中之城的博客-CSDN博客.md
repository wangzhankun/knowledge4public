---
{"dg-publish":true,"date":"2023-12-09","time":"20:57","progress":"进行中","tags":["OS"],"permalink":"/体系结构与操作系统/Linux内核/深入理解Linux中断机制(0.6)_linux中断处理机制_城中之城的博客-CSDN博客/","dgPassFrontmatter":true}
---

# 深入理解Linux中断机制(0.6)_linux中断处理机制_城中之城的博客-CSDN博客


**推荐阅读：**[操作系统导论](https://blog.csdn.net/orangeboyye/article/details/125270782)


#   一、中断基本原理

中断是计算机中非常重要的功能，其重要性不亚于人的神经系统加脉搏。虽然图灵机和冯诺依曼结构中没有中断，但是计算机如果真的没有中断的话，那么计算机就相当于是半个残疾人。今天我们就来全面详细地讲一讲中断。


##   1.1 中断的定义

我们先来看一下中断的定义：

中断机制：CPU在执行指令时，收到某个中断信号转而去执行预先设定好的代码，然后再返回到原指令流中继续执行，这就是中断机制。

可以发现中断的定义非常简单。我们根据中断的定义来画一张图：

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/B2AjbWOmqo8yT0xPsRzcPJrknGf.png)




在图灵机模型中，计算机是一直线性运行的。加入了中断之后，计算机就可以透明地在进程执行流中插入一段代码来执行。那么这么做的目的是什么呢？




##   1.2 中断的作用

设计中断机制的目的在于中断机制有以下4个作用，这些作用可以帮助操作系统实现自己的功能。这四个作用分别是：

**1.外设异步通知CPU：**外设发生了什么事情或者完成了什么任务或者有什么消息要告诉CPU，都可以异步给CPU发通知。例如，网卡收到了网络包，磁盘完成了IO任务，定时器的间隔时间到了，都可以给CPU发中断信号。

**2.CPU之间发送消息：**在SMP系统中，一个CPU想要给另一个CPU发送消息，可以给其发送IPI(处理器间中断)。

**3.处理CPU异常：**CPU在执行指令的过程中遇到了异常会给自己发送中断信号来处理异常。例如，做整数除法运算的时候发现被除数是0，访问虚拟内存的时候发现虚拟内存没有映射到物理内存上。

**4.实现系统调用：**早期的系统调用就是靠中断指令来实现的，后期虽然开发了专用的系统调用指令，但是其基本原理还是相似的。关于系统调用的详细原理，请参看 [《深入理解Linux系统调用与API》 ](https://blog.csdn.net/orangeboyye/article/details/125600135)。


##   1.3 中断的产生

那么中断信号又是如何产生的呢？中断信号的产生有以下4个来源：

1.外设，外设产生的中断信号是异步的，一般也叫做硬件中断(注意硬中断是另外一个概念)。硬件中断按照是否可以屏蔽分为可屏蔽中断和不可屏蔽中断。例如，网卡、磁盘、定时器都可以产生硬件中断。

2.CPU，这里指的是一个CPU向另一个CPU发送中断，这种中断叫做IPI(处理器间中断)。IPI也可以看出是一种特殊的硬件中断，因为它和硬件中断的模式差不多，都是异步的。

3.CPU异常，CPU在执行指令的过程中发现异常会向自己发送中断信号，这种中断是同步的，一般也叫做软件中断(注意软中断是另外一个概念)。CPU异常按照是否需要修复以及是否能修复分为3类：1.陷阱(trap)，不需要修复，中断处理完成后继续执行下一条指令，2.故障(fault)，需要修复也有可能修复，中断处理完成后重新执行之前的指令，3.中止(abort)，需要修复但是无法修复，中断处理完成后，进程或者内核将会崩溃。例如，缺页异常是一种故障，所以也叫缺页故障，缺页异常处理完成后会重新执行刚才的指令。

4.中断指令，直接用CPU指令来产生中断信号，这种中断和CPU异常一样是同步的，也可以叫做软件中断。例如，中断指令int 0x80可以用来实现系统调用。

中断信号的4个来源正好对应着中断的4个作用。前两种中断都可以叫做硬件中断，都是异步的；后两种中断都可以叫做软件中断，都是同步的。很多书上也把硬件中断叫做中断，把软件中断叫做异常。


##   1.4 中断的处理

那么中断信号又是如何处理的呢？也许你会觉得这不是很简单吗，前面的图里面不是画的很清楚吗，中断信号就是在正常的执行流中插入一段中断执行流啊。虽然这种中断处理方式简单又直接，但是它还存在着问题。

**执行场景(execute context)**

在继续讲解之前，我们先引入一个概念，执行场景(execute context)。在中断产生之前是没有这个概念的，有了中断之后，CPU就分为两个执行场景了，进程执行场景(process context)和中断执行场景(interrupt context)。那么哪些是进程执行场景哪些是中断执行场景呢？进程的执行是进程执行场景，同步中断的处理也是进程执行场景，异步中断的处理是中断执行场景。可能有的人会对同步中断的处理是进程执行场景感到疑惑，但是这也很好理解，因为同步中断处理是和当前指令相关的，可以看做是进程执行的一部分。而异步中断的处理和当前指令没有关系，所以不是进程执行场景。

进程执行场景和中断执行场景有两个区别：一是进程执行场景是可以调度、可以休眠的，而中断执行场景是不可以调度不可用休眠的；二是在进程执行场景中是可以接受中断信号的，而在中断执行场景中是屏蔽中断信号的。所以如果中断执行场景的执行时间太长的话，就会影响我们对新的中断信号的响应性，所以我们需要尽量缩短中断执行场景的时间。为此我们对异步中断的处理有下面两类办法：

**1.立即完全处理:**

对于简单好处理的异步中断可以立即进行完全处理。

**2.立即预处理 + 稍后完全处理:**

对于处理起来比较耗时的中断可以采取立即预处理加稍后完全处理的方式来处理。

为了方便表述，我们把立即完全处理和立即预处理都叫做中断预处理，把稍后完全处理叫做中断后处理。中断预处理只有一种实现方式，就是直接处理。但是中断后处理却有很多种方法，其处理方法可以运行在中断执行场景，也可以运行在进程执行场景，前者叫做直接中断后处理，后者叫做线程化中断后处理。

在Linux中，中断预处理叫做上半部，中断后处理叫做下半部。由于“上半部、下半部”词义不明晰，我们在本文中都用中断预处理、中断后处理来称呼。中断预处理只有一种方法，叫做hardirq(硬中断)。中断后处理有很多种方法，分为两类，直接中断后处理有softirq(软中断)、tasklet(微任务)，线程化中断后处理有workqueue(工作队列)、threaded_irq(中断线程)。

硬中断、软中断是什么意思呢？本来的异步中断处理是直接把中断处理完的，整个过程是屏蔽中断的，现在，把整个过程分成了两部分，前半部分还是屏蔽中断的，叫做硬中断，处理与硬件相关的紧急事物，后半部分不再屏蔽中断，叫做软中断，处理剩余的事物。由于软中断中不再屏蔽中断信号，所以提高了系统对中断的响应性。

**注意硬件中断、软件中断，硬中断、软中断是不同的概念，分别指的是中断的来源和中断的处理方式。**


##   1.5 中断向量号

不同的中断信号需要有不同的处理方式，那么系统是怎么区分不同的中断信号呢？是靠中断向量号。每一个中断信号都有一个中断向量号，中断向量号是一个整数。CPU收到一个中断信号会根据这个信号的中断的向量号去查询中断向量表，根据向量表里面的指示去调用相应的处理函数。

中断信号和中断向量号是如何对应的呢？对于CPU异常来说，其向量号是由CPU架构标准规定的。对于外设来说，其向量号是由设备驱动动态申请的。对于IPI中断和指令中断来说，其向量号是由内核规定的。

那么中断向量表是什么格式，应该如何设置呢，这个我们后面会讲。


##   1.6 中断框架结构

有了前面这么多基础知识，下面我们对中断机制做个概览。

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/Xd5ub0VLPoc6FOxjofKcfzH3nJh.png)


中断信号的产生有两类，分别是异步中断和同步中断，异步中断包括外设中断和IPI中断，同步中断包括CPU异常和指令中断。无论是同步中断还是异步中断，都要经过中断向量表进行处理。对于同步中断的处理是异常处理或者系统调用，它们都是进程执行场景，所以没有过多的处理方法，就是直接执行。对于异步中断的处理，由于直接调用处理是属于中断执行场景，默认的中断执行场景是会屏蔽中断的，这会降低系统对中断的响应性，所以内核开发出了很多的方法来解决这个问题。



下面的章节是对这个图的详细解释，我们先讲中断向量表，再讲中断的产生，最后讲中断的处理。

**本文后面都是以x86 CPU架构进行讲解的。**


#   二、中断流程

CPU收到中断信号后会首先保存被中断程序的状态，然后再去执行中断处理程序，最后再返回到原程序中被中断的点去执行。具体是怎么做呢？我们以x86为例讲解一下。


##   2.1 保存现场

CPU收到中断信号后会首先把一些数据push到内核栈上，保存的数据是和当前执行点相关的，这样中断完成后就可以返回到原执行点。如果CPU当前处于用户态，则会先切换到内核态，把用户栈切换为内核栈再去保存数据(内核栈的位置是在当前线程的TSS中获取的)。下面我们画个图看一下：

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/T5iGbKz5molPVIxCHMSc2Kbbnfd.png)


CPU都push了哪些数据呢？分为两种情况。当CPU处于内核态时，会push寄存器EFLAGS、CS、EIP的值到栈上，对于有些CPU异常还会push Error Code。Push CS、EIP是为了中断完成后返回到原执行点，push EFLAGS是为了恢复之前的CPU状态。当CPU处于用户态时，会先切换到内核态，把栈切换到内核栈，然后push寄存器SS(old)、ESP(old)、EFLAGS、CS、EIP的值到新的内核栈，对于有些CPU异常还会push Error Code。Push SS(old)、ESP(old)，是为了中断返回的时候可以切换回原来的栈。有些CPU异常会push Error Code，这样可以方便中断处理程序知道更具体的异常信息。不是所有的CPU异常都会push Error Code，具体哪些会哪些不会在3.1节中会讲。



上图是32位的情况，64位的时候会push 64位下的寄存器。


##   2.2 查找向量表

保存完被中断程序的信息之后，就要去执行中断处理程序了。CPU会根据当前中断信号的向量号去查询中断向量表找到中断处理程序。CPU是如何获得当前中断信号的向量号的呢，如果是CPU异常可以在CPU内部获取，如果是指令中断，在指令中就有向量号，如果是硬件中断，则可以从中断控制器中获取中断向量号。那CPU又是怎么找到中断向量表呢，是通过IDTR寄存器。IDTR寄存器的格式如下图所示：

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/CbIHboALvofw1RxYeqtcXz0tnBb.png)


IDTR寄存器由两部分组成：一部分是IDT基地址，在32位上是32位，在64位上是64位，是虚拟内存上的地址；一部分是IDT限长，是16位，单位是字节，代表中断向量表的长度。虽然x86支持256个中断向量，但是系统不一定要用满256个，IDT限长用来指定中断向量表的大小。系统在启动时分配一定大小的内存用来做中断向量表，然后通过LIDT指令设置IDTR寄存器的值，这样CPU就知道中断向量表的位置和大小了。



IDTR寄存器设置好之后，中断向量表的内容还是可以再修改的。该如何修改呢，这就需要我们知道中断向量表的数据结构了。中断向量表是一个数组结构，数组的每一项叫做中断向量表条目，每个条目都是一个门描述符(gate descriptor)。门描述符一共有三种类型，不同类型的具体结构不同，三类门描述符分别是任务门描述符、中断门描述符、陷阱门描述符。任务门不太常用，后面我们都默认忽略任务门。中断门一般用于硬件中断，陷阱门一般用于软件中断。32位下的门描述符是8字节，下面是它们的具体结构：

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/WMArblkI6oRFH8x8x5Zc1IwxnvP.png)


Segment Selector是段选择符，Offset是段偏移，两个段偏移共同构成一个32的段偏移。p代表段是否加载到了内存。dpl是段描述符特权级。d为0代表是16位描述符，d为1代表是32位描述符。Type 是8 9 10三位，代表描述符的类型。



下面看一下64位门描述符的格式：

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/PXccbYJ5QooTurxyopOcDTGanNg.png)


可以看到64位和32位最主要的变化是把段偏移变成了64位。



关于x86的分段机制，这里就不展开讨论了，简介地介绍一下其在Linux内核中的应用。Linux内核并不使用x86的分段机制，但是x86上特权级的切换还是需要用到分段。所以Linux采取的方法是，定义了四个段__KERNEL_CS、__KERNEL_DS、__USER_CS、__USER_DS，这四个段的段基址都是0，段限长都是整个内存大小，所以在逻辑上相当于不分段。但是这四个段的特权级不一样，__KERNEL_CS、__KERNEL_DS是内核特权级，用在内核执行时，__USER_CS、__USER_DS是用户特权级，用在进程执行时。由于中断都运行在内核，所以所有中断的门描述符的段选择符都是__KERNEL_CS，而段偏移实际上就是终端处理函数的虚拟地址。

CPU现在已经把被中断的程序现场保存到内核栈上了，又得到了中断向量号，然后就根据中断向量号从中断向量表中找到对应的门描述符，对描述符做一番安全检查之后，CPU就开始执行中断处理函数(就是门描述符中的段偏移)。中断处理函数的最末尾执行IRET指令，这个指令会根据前面保存在栈上的数据跳回到原来的指令继续执行。


#   三、软件中断

对中断的基本概念和整个处理流程有了大概的认识之后，我们来看一下软件中断的产生。软件中断有两类，CPU异常和指令中断。我们先来看CPU异常：


##   3.1 CPU异常

CPU在执行指令的过程中遇到了异常就会给自己发送中断信号。注意异常不一定是错误，只要是异于平常就都是异常。有些异常不但不是错误，它还是实现内核重要功能的方法。CPU异常分为3类：1.陷阱(trap)，陷阱并不是错误，而是想要陷入内核来执行一些操作，中断处理完成后继续执行之前的下一条指令，2.故障(fault)，故障是程序遇到了问题需要修复，问题不一定是错误，如果问题能够修复，那么中断处理完成后会重新执行之前的指令，如果问题无法修复那就是错误，当前进程将会被杀死。3.中止(abort)，系统遇到了很严重的错误，无法修改，一般系统会崩溃。

CPU异常的含义和其向量号都是架构标准提前定义好的，下面我们来看一下。

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/Z6h1bOT8Bot0OCxtWb3ckoCOnjc.png)


x86一共有256个中断向量号，前32个(0-31)是Intel预留的，其中0-21(除了15)都已分配给特定的CPU异常。32-255是给硬件中断和指令中断保留的向量号。




##   3.2 指令中断

指令中断和CPU异常有很大的相似性，都属于同步中断，都是属于因为执行指令而产生了中断。不同的是CPU异常不是在执行特定的指令时发生的，也不是必然发生。而指令中断是执行特定的指令而发生的中断，设计这些指令的目的就是为了产生中断的，而且一定会产生中断或者有些条件成立的情况下一定会产生中断。其中指令INT n可以产生任意中断，n可以取任意值。Linux用int 0x80来作为系统调用的指令。关于系统调用的详细情况，请参看 [《深入理解Linux系统调用与API》 ](https://blog.csdn.net/orangeboyye/article/details/125600135)。


#   四、硬件中断

硬件中断分为外设中断和处理器间中断(IPI)，下面我们先来看一下外设中断。


##   4.1 外设中断

外设中断和软件中断有一个很大的不同，软件中断是CPU自己给自己发送中断，而外设中断是需要外设发送中断给CPU。外设想要给CPU发送中断，那就必须要连接到CPU，不可能隔空发送。那么怎么连接呢，如果所有外设都直接连到CPU，显然是不可能的。因为一个计算机系统中的外设是非常多的，而且多种多样，CPU无法提前为所有外设设计和预留接口。所以需要一个中间设备，就像秘书一样替CPU连接到所有的外设并接收中断信号，再转发给CPU，这个设备就叫做中断控制器(Interrupt Controller )。

在x86上，在UP时代的时候，有一个中断控制器叫做PIC(Programmable Interrupt Controller )。所有的外设都连接到PIC上，PIC再连接到CPU的中断引脚上。外设给PIC发中断，PIC再把中断转发给CPU。由于PIC的设计问题，一个PIC只能连接8个外设，所以后来把两个PIC级联起来，第二个PIC连接到第一个PIC的一个引脚上，这样一共能连接15个外设。

到了SMP时代的时候，PIC显然不能胜任工作了，于是Intel开发了APIC(Advanced PIC)。APIC分为两个部分：一部分是Local APIC，有NR_CPU个，每个CPU都连接一个Local APIC；一部分是IO APIC，只有一个，所有的外设都连接到这个IO APIC上。IO APIC连接到所有的Local APIC上，当外设向IO APIC发送中断时，IO APIC会把中断信号转发给某个Local APIC。有些per CPU的设备是直接连接到Local APIC的，可以通过Local APIC直接给自己的CPU发送中断。

外设中断并不是直接分配中断向量号，而是直接分配IRQ号，然后IRQ+32就是其中断向量号。有些外设的IRQ是内核预先设定好的，有些是行业默认的IRQ号。

关于APIC的细节这里就不再阐述了，推荐大家去看《Interrupt in Linux (硬件篇)》，对APIC讲的比较详细。


##   4.2 处理器间中断

在SMP系统中，多个CPU之间有时候也需要发送消息，于是就产生了处理器间中断(IPI)。IPI既像软件中断又像硬件中断，它的产生像软件中断，是在程序中用代码发送的，而它的处理像硬件中断，是异步的。我们这里把IPI看作是硬件中断，因为一个CPU可以把另外一个CPU看做外设，就相当于是外设发来的中断。


#   五、中断处理

终于讲到中断处理了，我们再把之前的中间机制图搬过来，再回顾一下：

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/Is4gb0U0soDNEBxqOKpcYR6pnTg.png)


无论是硬件中断还是软件中断，都是通过中断向量表进行处理的。但是不同的是，软件中断的处理程序是属于进程执行场景，所以直接把中断处理程序设置好就行了，中断处理程序怎么写也没有什么要顾虑的。而硬件中断的处理程序就不同了，它是属于中断执行场景。不仅其中断处理函数中不能调用会阻塞、休眠的函数，而且处理程序本身要尽量的短，越短越好。所以为了使硬件中断处理函数尽可能的短，Linux内核开发了一大堆方法。这些方法包括硬中断(hardirq)、软中断(softirq)、微任务(tasklet)、中断线程(threaded irq)、工作队列(workqueue)。其实硬中断严格来说不算是一种方法，因为它是中断处理的必经之路，它就是中断向量表里面设置的处理函数。为了和软中断进行区分，才把硬中断叫做硬中断。硬中断和软中断都是属于中断执行场景，而中断线程和工作队列是属于进程执行场景。把硬件中断的处理任务放到进程场景里面来做，大大提高了中断处理的灵活性。



由于软件中断的处理都是直接处理，都是内核本身直接写好了的，一般都接触不到，而硬件中断的处理和硬件驱动密切相关，所以很多书上所讲的中断处理都是指的硬件中断的处理。但是我们今天把软件中断的处理也讲一讲，这里只讲异常处理，系统调用部分请参看 [《深入理解Linux系统调用与API》 ](https://blog.csdn.net/orangeboyye/article/details/125600135)。


##   5.1 异常处理

x86上的异常处理是怎么设置的呢？我们把前面的图搬过来看一下：

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/VB57bqeu7oFqY6xFHGycSStinSg.png)


我们对照着这个图去捋代码。首先我们需要分配一片内存来存放中断向量表，这个是在如下代码中分配的。
linux-src/arch/x86/kernel/idt.c



```C
/* Must be page-aligned because the real IDT is used in the cpu entry area */
static gate_desc idt_table[IDT_ENTRIES] __page_aligned_bss;
```

linux-src/arch/x86/include/asm/desc_defs.h

```C
struct idt_bits {
        u16 ist        : 3,
      zero        : 5,
      type        : 5,
      dpl        : 2,
        p        : 1;
} __attribute__((packed));

struct gate_struct {
        u16                offset_low;
        u16                segment;
        struct idt_bits        bits;
        u16                offset_middle;
#ifdef CONFIG_X86_64
        u32                offset_high;
        u32                reserved;
#endif
} __attribute__((packed));

typedef struct gate_struct gate_desc;
```

linux-src/arch/x86/include/asm/segment.h

```C
#define IDT_ENTRIES                        256
```

可以看到我们的中断向量表idt_table是门描述符gate_desc的数组，数组大小是IDT_ENTRIES 256。门描述符gate_desc的定义和前面画的图是一致的，注意x86是小端序。

寄存器IDTR内容包括IDT的基址和限长，为此我们专门定义一个数据结构包含IDT的基址和限长，然后就可以用这个变量通过LIDT指令来设置IDTR寄存器了。
linux-src/arch/x86/kernel/idt.c

```C
static struct desc_ptr idt_descr __ro_after_init = {
        .size                = IDT_TABLE_SIZE - 1,
        .address        = (unsigned long) idt_table,
};
```

linux-src/arch/x86/include/asm/desc.h

```C
#define load_idt(dtr)                                native_load_idt(dtr)
static __always_inline void native_load_idt(const struct desc_ptr *dtr)
{
        asm volatile("lidt %0"::"m" (*dtr));
}
```

有一点需要注意的，我们并不是需要把idt_table完全初始化好了再去load_idt，我们可以先初始化一部分的idt_table，然后再去load_idt，之后可以不停地去完善idt_table。

我们先来看一下内核是什么时候load_idt的，其实内核有多次load_idt，不过实际上只需要一次就够了。

调用栈如下：
start_kernel
setup_arch
idt_setup_early_traps

代码如下：
linux-src/arch/x86/kernel/idt.c

```C
void __init idt_setup_early_traps(void)
{
        idt_setup_from_table(idt_table, early_idts, ARRAY_SIZE(early_idts), true);
        load_idt(&idt_descr);
}
```

这是内核在start_kernel里第一次设置IDTR，虽然之前的代码里也有设置过IDTR，我们就不考虑了。load_idt之后，IDT就生效了，只不过这里IDT还没有设置全，只设置了少数几个CPU异常的处理函数，我们来看一下是怎么设置的。

linux-src/arch/x86/kernel/idt.c

```C
static __init void
idt_setup_from_table(gate_desc *idt, const struct idt_data *t, int size, bool sys)
{
        gate_desc desc;

        for (; size > 0; t++, size--) {
                idt_init_desc(&desc, t);
                write_idt_entry(idt, t->vector, &desc);
                if (sys)
                        set_bit(t->vector, system_vectors);
        }
}

static inline void idt_init_desc(gate_desc *gate, const struct idt_data *d)
{
        unsigned long addr = (unsigned long) d->addr;

        gate->offset_low        = (u16) addr;
        gate->segment                = (u16) d->segment;
        gate->bits                = d->bits;
        gate->offset_middle        = (u16) (addr >> 16);
#ifdef CONFIG_X86_64
        gate->offset_high        = (u32) (addr >> 32);
        gate->reserved                = 0;
#endif
}

#define write_idt_entry(dt, entry, g)                native_write_idt_entry(dt, entry, g)
static inline void native_write_idt_entry(gate_desc *idt, int entry, const gate_desc *gate)
{
        memcpy(&idt[entry], gate, sizeof(*gate));
}
```

在函数idt_setup_from_table里会定义一个gate_desc的临时变量，然后用idt_data来初始化这个gate_desc，最后会把gate_desc复制到idt_table中对应的位置中去。这样中断向量表中的这一项就生效了。

下面我们再来看看idt_data数据是怎么来的：
linux-src/arch/x86/kernel/idt.c

```C
static const __initconst struct idt_data early_idts[] = {
        INTG(X86_TRAP_DB,                asm_exc_debug),
        SYSG(X86_TRAP_BP,                asm_exc_int3),
};

#define G(_vector, _addr, _ist, _type, _dpl, _segment)        \
        {                                                \
                .vector                = _vector,                \
                .bits.ist        = _ist,                        \
                .bits.type        = _type,                \
                .bits.dpl        = _dpl,                        \
                .bits.p                = 1,                        \
                .addr                = _addr,                \
                .segment        = _segment,                \
        }

/* Interrupt gate */
#define INTG(_vector, _addr)                                \
        G(_vector, _addr, DEFAULT_STACK, GATE_INTERRUPT, DPL0, __KERNEL_CS)

/* System interrupt gate */
#define SYSG(_vector, _addr)                                \
        G(_vector, _addr, DEFAULT_STACK, GATE_INTERRUPT, DPL3, __KERNEL_CS)
```

linux-src/arch/x86/kernel/traps.c

```C
DEFINE_IDTENTRY_DEBUG(exc_debug)
{
        exc_debug_kernel(regs, debug_read_clear_dr6());
}

EFINE_IDTENTRY_RAW(exc_int3)
{
        /*
         * poke_int3_handler() is completely self contained code; it does (and
         * must) *NOT* call out to anything, lest it hits upon yet another
         * INT3.
         */
        if (poke_int3_handler(regs))
                return;

        /*
         * irqentry_enter_from_user_mode() uses static_branch_{,un}likely()
         * and therefore can trigger INT3, hence poke_int3_handler() must
         * be done before. If the entry came from kernel mode, then use
         * nmi_enter() because the INT3 could have been hit in any context
         * including NMI.
         */
        if (user_mode(regs)) {
                irqentry_enter_from_user_mode(regs);
                instrumentation_begin();
                do_int3_user(regs);
                instrumentation_end();
                irqentry_exit_to_user_mode(regs);
        } else {
                irqentry_state_t irq_state = irqentry_nmi_enter(regs);

                instrumentation_begin();
                if (!do_int3(regs))
                        die("int3", regs, 0);
                instrumentation_end();
                irqentry_nmi_exit(regs, irq_state);
        }
}
```

early_idts是idt_data的数组，在这里定义了两个中断向量表的条目，分别是X86_TRAP_DB和X86_TRAP_BP，它们的中断处理函数分别是asm_exc_debug和asm_exc_int3。这里只是设置了两个中断向量表条目，并且把IDTR寄存器设置好了，后来就不需要再设置IDTR寄存器了。

下面我们看一下所有CPU异常的处理函数是怎么设置的。

先看调用栈：
start_kernel
trap_init
idt_setup_traps

代码如下：
linux-src/arch/x86/kernel/idt.c

```C
void __init idt_setup_traps(void)
{
        idt_setup_from_table(idt_table, def_idts, ARRAY_SIZE(def_idts), true);
}

static const __initconst struct idt_data def_idts[] = {
        INTG(X86_TRAP_DE,                asm_exc_divide_error),
        ISTG(X86_TRAP_NMI,                asm_exc_nmi, IST_INDEX_NMI),
        INTG(X86_TRAP_BR,                asm_exc_bounds),
        INTG(X86_TRAP_UD,                asm_exc_invalid_op),
        INTG(X86_TRAP_NM,                asm_exc_device_not_available),
        INTG(X86_TRAP_OLD_MF,                asm_exc_coproc_segment_overrun),
        INTG(X86_TRAP_TS,                asm_exc_invalid_tss),
        INTG(X86_TRAP_NP,                asm_exc_segment_not_present),
        INTG(X86_TRAP_SS,                asm_exc_stack_segment),
        INTG(X86_TRAP_GP,                asm_exc_general_protection),
        INTG(X86_TRAP_SPURIOUS,                asm_exc_spurious_interrupt_bug),
        INTG(X86_TRAP_MF,                asm_exc_coprocessor_error),
        INTG(X86_TRAP_AC,                asm_exc_alignment_check),
        INTG(X86_TRAP_XF,                asm_exc_simd_coprocessor_error),

#ifdef CONFIG_X86_32
        TSKG(X86_TRAP_DF,                GDT_ENTRY_DOUBLEFAULT_TSS),
#else
        ISTG(X86_TRAP_DF,                asm_exc_double_fault, IST_INDEX_DF),
#endif
        ISTG(X86_TRAP_DB,                asm_exc_debug, IST_INDEX_DB),

#ifdef CONFIG_X86_MCE
        ISTG(X86_TRAP_MC,                asm_exc_machine_check, IST_INDEX_MCE),
#endif

#ifdef CONFIG_AMD_MEM_ENCRYPT
        ISTG(X86_TRAP_VC,                asm_exc_vmm_communication, IST_INDEX_VC),
#endif

        SYSG(X86_TRAP_OF,                asm_exc_overflow),
#if defined(CONFIG_IA32_EMULATION)
        SYSG(IA32_SYSCALL_VECTOR,        entry_INT80_compat),
#elif defined(CONFIG_X86_32)
        SYSG(IA32_SYSCALL_VECTOR,        entry_INT80_32),
#endif
};
```

可以看到这次设置非常简单，就是调用了一下idt_setup_from_table，并没有调用load_idt。主要是数组def_idts里面包含了大部分的CPU异常处理。但是没缺页异常，缺页异常是单独设置。设置路径如下：

调用栈：
start_kernel
setup_arch
idt_setup_early_pf

代码如下：
linux-src/arch/x86/kernel/idt.c

```C
void __init idt_setup_early_pf(void)
{
        idt_setup_from_table(idt_table, early_pf_idts,
                             ARRAY_SIZE(early_pf_idts), true);
}

static const __initconst struct idt_data early_pf_idts[] = {
        INTG(X86_TRAP_PF,                asm_exc_page_fault),
};
```

现在CPU异常的中断处理函数就全部设置完成了，想要研究具体哪个异常是怎么处理的同学，可以去跟踪研究一下相应的函数。


##   5.2 硬中断(hardirq)

硬件中断的中断处理和软件中断有一部分是相同的，有一部分却有很大的不同。对于IPI中断和per CPU中断，其设置是和软件中断相同的，都是一步到位设置到具体的处理函数。但是对于余下的外设中断，只是设置了入口函数，并没有设置具体的处理函数，而且是所有的外设中断的处理函数都统一到了同一个入口函数。然后在这个入口函数处会调用相应的irq描述符的handler函数，这个handler函数是中断控制器设置的。中断控制器设置的这个handler函数会处理与这个中断控制器相关的一些事物，然后再调用具体设备注册的irqaction的handler函数进行具体的中断处理。

我们先来看一下对中断向量表条目的设置代码。

调用栈如下：
start_kernel
init_IRQ
native_init_IRQ
idt_setup_apic_and_irq_gates

代码如下：
linux-src/arch/x86/kernel/idt.c

```C
/**
 * idt_setup_apic_and_irq_gates - Setup APIC/SMP and normal interrupt gates
 */
void __init idt_setup_apic_and_irq_gates(void)
{
        int i = FIRST_EXTERNAL_VECTOR;
        void *entry;

        idt_setup_from_table(idt_table, apic_idts, ARRAY_SIZE(apic_idts), true);

        for_each_clear_bit_from(i, system_vectors, FIRST_SYSTEM_VECTOR) {
                entry = irq_entries_start + 8 * (i - FIRST_EXTERNAL_VECTOR);
                set_intr_gate(i, entry);
        }

#ifdef CONFIG_X86_LOCAL_APIC
        for_each_clear_bit_from(i, system_vectors, NR_VECTORS) {
                /*
                 * Don't set the non assigned system vectors in the
                 * system_vectors bitmap. Otherwise they show up in
                 * /proc/interrupts.
                 */
                entry = spurious_entries_start + 8 * (i - FIRST_SYSTEM_VECTOR);
                set_intr_gate(i, entry);
        }
#endif
        /* Map IDT into CPU entry area and reload it. */
        idt_map_in_cea();
        load_idt(&idt_descr);

        /* Make the IDT table read only */
        set_memory_ro((unsigned long)&idt_table, 1);

        idt_setup_done = true;
}

static const __initconst struct idt_data apic_idts[] = {
#ifdef CONFIG_SMP
        INTG(RESCHEDULE_VECTOR,                        asm_sysvec_reschedule_ipi),
        INTG(CALL_FUNCTION_VECTOR,                asm_sysvec_call_function),
        INTG(CALL_FUNCTION_SINGLE_VECTOR,        asm_sysvec_call_function_single),
        INTG(IRQ_MOVE_CLEANUP_VECTOR,                asm_sysvec_irq_move_cleanup),
        INTG(REBOOT_VECTOR,                        asm_sysvec_reboot),
#endif

#ifdef CONFIG_X86_THERMAL_VECTOR
        INTG(THERMAL_APIC_VECTOR,                asm_sysvec_thermal),
#endif

#ifdef CONFIG_X86_MCE_THRESHOLD
        INTG(THRESHOLD_APIC_VECTOR,                asm_sysvec_threshold),
#endif

#ifdef CONFIG_X86_MCE_AMD
        INTG(DEFERRED_ERROR_VECTOR,                asm_sysvec_deferred_error),
#endif

#ifdef CONFIG_X86_LOCAL_APIC
        INTG(LOCAL_TIMER_VECTOR,                asm_sysvec_apic_timer_interrupt),
        INTG(X86_PLATFORM_IPI_VECTOR,                asm_sysvec_x86_platform_ipi),
# ifdef CONFIG_HAVE_KVM
        INTG(POSTED_INTR_VECTOR,                asm_sysvec_kvm_posted_intr_ipi),
        INTG(POSTED_INTR_WAKEUP_VECTOR,                asm_sysvec_kvm_posted_intr_wakeup_ipi),
        INTG(POSTED_INTR_NESTED_VECTOR,                asm_sysvec_kvm_posted_intr_nested_ipi),
# endif
# ifdef CONFIG_IRQ_WORK
        INTG(IRQ_WORK_VECTOR,                        asm_sysvec_irq_work),
# endif
        INTG(SPURIOUS_APIC_VECTOR,                asm_sysvec_spurious_apic_interrupt),
        INTG(ERROR_APIC_VECTOR,                        asm_sysvec_error_interrupt),
#endif
};

static __init void set_intr_gate(unsigned int n, const void *addr)
{
        struct idt_data data;

        init_idt_data(&data, n, addr);

        idt_setup_from_table(idt_table, &data, 1, false);
}
```

linux-src/arch/x86/include/asm/desc.h

```C
static inline void init_idt_data(struct idt_data *data, unsigned int n,
                                 const void *addr)
{
        BUG_ON(n > 0xFF);

        memset(data, 0, sizeof(*data));
        data->vector        = n;
        data->addr        = addr;
        data->segment        = __KERNEL_CS;
        data->bits.type        = GATE_INTERRUPT;
        data->bits.p        = 1;
}
```

linux-src/arch/x86/include/asm/idtentry.h

```C
SYM_CODE_START(irq_entries_start)
    vector=FIRST_EXTERNAL_VECTOR
    .rept NR_EXTERNAL_VECTORS
        UNWIND_HINT_IRET_REGS
0 :
        .byte        0x6a, vector
        jmp        asm_common_interrupt
        nop
        /* Ensure that the above is 8 bytes max */
        . = 0b + 8
        vector = vector+1
    .endr
SYM_CODE_END(irq_entries_start)

#define DEFINE_IDTENTRY_IRQ(func)                                        \static void __##func(struct pt_regs *regs, u32 vector);                        \
                                                                        \__visible noinstr void func(struct pt_regs *regs,                        \
                            unsigned long error_code)                        \{                                                                        \
        irqentry_state_t state = irqentry_enter(regs);                        \
        u32 vector = (u32)(u8)error_code;                                \
                                                                        \
        instrumentation_begin();                                        \
        kvm_set_cpu_l1tf_flush_l1d();                                        \
        run_irq_on_irqstack_cond(__##func, regs, vector);                \
        instrumentation_end();                                                \
        irqentry_exit(regs, state);                                        \}                                                                        \
                                                                        \static noinline void __##func(struct pt_regs *regs, u32 vector)
```

linux-src/arch/x86/include/asm/irq_stack.h

```C
#define run_irq_on_irqstack_cond(func, regs, vector)                        \{                                                                        \
        assert_function_type(func, void (*)(struct pt_regs *, u32));        \
        assert_arg_type(regs, struct pt_regs *);                        \
        assert_arg_type(vector, u32);                                        \
                                                                        \
        call_on_irqstack_cond(func, regs, ASM_CALL_IRQ,                        \
                              IRQ_CONSTRAINTS, regs, vector);                \}

#define call_on_irqstack_cond(func, regs, asm_call, constr, c_args...)        \{                                                                        \
        /*                                                                \
         * User mode entry and interrupt on the irq stack do not        \
         * switch stacks. If from user mode the task stack is empty.        \
         */                                                                \
        if (user_mode(regs) || __this_cpu_read(hardirq_stack_inuse)) {        \
                irq_enter_rcu();                                        \
                func(c_args);                                                \
                irq_exit_rcu();                                                \
        } else {                                                        \
                /*                                                        \
                 * Mark the irq stack inuse _before_ and unmark _after_        \
                 * switching stacks. Interrupts are disabled in both        \
                 * places. Invoke the stack switch macro with the call        \
                 * sequence which matches the above direct invocation.        \
                 */                                                        \
                __this_cpu_write(hardirq_stack_inuse, true);                \
                call_on_irqstack(func, asm_call, constr);                \
                __this_cpu_write(hardirq_stack_inuse, false);                \
        }                                                                \}

#define call_on_irqstack(func, asm_call, argconstr...)                        \
        call_on_stack(__this_cpu_read(hardirq_stack_ptr),                \
                      func, asm_call, argconstr)

#define call_on_stack(stack, func, asm_call, argconstr...)                \{                                                                        \
        register void *tos asm("r11");                                        \
                                                                        \
        tos = ((void *)(stack));                                        \
                                                                        \
        asm_inline volatile(                                                \
        "movq        %%rsp, (%[tos])                                \n"                \
        "movq        %[tos], %%rsp                                \n"                \
                                                                        \
        asm_call                                                        \
                                                                        \
        "popq        %%rsp                                        \n"                \
                                                                        \
        : "+r" (tos), ASM_CALL_CONSTRAINT                                \
        : [__func] "i" (func), [tos] "r" (tos) argconstr                \
        : "cc", "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10",        \
          "memory"                                                        \
        );                                                                \}
```

linux-src/arch/x86/kernel/irq.c

```C
DEFINE_IDTENTRY_IRQ(common_interrupt)
{
        struct pt_regs *old_regs = set_irq_regs(regs);
        struct irq_desc *desc;

        /* entry code tells RCU that we're not quiescent.  Check it. */
        RCU_LOCKDEP_WARN(!rcu_is_watching(), "IRQ failed to wake up RCU");

        desc = __this_cpu_read(vector_irq[vector]);
        if (likely(!IS_ERR_OR_NULL(desc))) {
                handle_irq(desc, regs);
        } else {
                ack_APIC_irq();

                if (desc == VECTOR_UNUSED) {
                        pr_emerg_ratelimited("%s: %d.%u No irq handler for vector\n",
                                             __func__, smp_processor_id(),
                                             vector);
                } else {
                        __this_cpu_write(vector_irq[vector], VECTOR_UNUSED);
                }
        }

        set_irq_regs(old_regs);
}

static __always_inline void handle_irq(struct irq_desc *desc,
                                       struct pt_regs *regs)
{
        if (IS_ENABLED(CONFIG_X86_64))
                generic_handle_irq_desc(desc);
        else
                __handle_irq(desc, regs);
}
```

linux-src/arch/x86/kernel/irqinit.c

```C
DEFINE_PER_CPU(vector_irq_t, vector_irq) = {
        [0 ... NR_VECTORS - 1] = VECTOR_UNUSED,
};
```

linux-src/arch/x86/include/asm/hw_irq.h

```C
typedef struct irq_desc* vector_irq_t[NR_VECTORS];
```

linux-src/include/linux/irqdesc.h

```C
static inline void generic_handle_irq_desc(struct irq_desc *desc)
{
        desc->handle_irq(desc);
}
```

从上面的代码可以看出，对硬件中断的设置分为两个部分，一部分就像前面的软件中断的方式一样，是从apic_idts数组设置的，设置的都是一些IPI和per CPU的中断。另一部分是把所有剩余的硬件中断的处理函数都设置为irq_entries_start，irq_entries_start会调用common_interrupt函数。在common_interrupt函数中会根据中断向量号去读取per CPU的数组变量vector_irq，得到一个irq_desc。最终会调用irq_desc中的handle_irq来处理这个中断。

对于外设中断为什么要采取这样的处理方式呢？有两个原因，1是因为外设中断和中断控制器相关联，这样可以统一处理与中断控制器相关的事物，2是因为外设中断的驱动执行比较晚，有些设备还是可以热插拔的，直接把它们放到中断向量表上比较麻烦。有个irq_desc这个中间层，设备驱动后面只需要调用函数request_irq来注册ISR，只处理与设备相关的业务就可以了，而不用考虑和中断控制器硬件相关的处理。

我们先来看一下vector_irq数组是怎么初始化的。

linux-src/arch/x86/kernel/apic/vector.c

```C
void lapic_online(void)
{
        unsigned int vector;

        lockdep_assert_held(&vector_lock);

        /* Online the vector matrix array for this CPU */
        irq_matrix_online(vector_matrix);

        /*
         * The interrupt affinity logic never targets interrupts to offline
         * CPUs. The exception are the legacy PIC interrupts. In general
         * they are only targeted to CPU0, but depending on the platform
         * they can be distributed to any online CPU in hardware. The
         * kernel has no influence on that. So all active legacy vectors
         * must be installed on all CPUs. All non legacy interrupts can be
         * cleared.
         */
        for (vector = 0; vector < NR_VECTORS; vector++)
                this_cpu_write(vector_irq[vector], __setup_vector_irq(vector));
}

static struct irq_desc *__setup_vector_irq(int vector)
{
        int isairq = vector - ISA_IRQ_VECTOR(0);

        /* Check whether the irq is in the legacy space */
        if (isairq < 0 || isairq >= nr_legacy_irqs())
                return VECTOR_UNUSED;
        /* Check whether the irq is handled by the IOAPIC */
        if (test_bit(isairq, &io_apic_irqs))
                return VECTOR_UNUSED;
        return irq_to_desc(isairq);
}
```

linux-src/kernel/irq/irqdesc.c

```C
struct irq_desc *irq_to_desc(unsigned int irq)
{
        return radix_tree_lookup(&irq_desc_tree, irq);
}
```

可以看出vector_irq数组的初始化数据是从irq_desc_tree来的，我们再来看一下irq_desc_tree是怎么初始化的。

linux-src/kernel/irq/irqdesc.c

```C
int __init early_irq_init(void)
{
        int i, initcnt, node = first_online_node;
        struct irq_desc *desc;

        init_irq_default_affinity();

        /* Let arch update nr_irqs and return the nr of preallocated irqs */
        initcnt = arch_probe_nr_irqs();
        printk(KERN_INFO "NR_IRQS: %d, nr_irqs: %d, preallocated irqs: %d\n",
               NR_IRQS, nr_irqs, initcnt);

        if (WARN_ON(nr_irqs > IRQ_BITMAP_BITS))
                nr_irqs = IRQ_BITMAP_BITS;

        if (WARN_ON(initcnt > IRQ_BITMAP_BITS))
                initcnt = IRQ_BITMAP_BITS;

        if (initcnt > nr_irqs)
                nr_irqs = initcnt;

        for (i = 0; i < initcnt; i++) {
                desc = alloc_desc(i, node, 0, NULL, NULL);
                set_bit(i, allocated_irqs);
                irq_insert_desc(i, desc);
        }
        return arch_early_irq_init();
}
```

可以看到vector_irq数组的内容是在系统初始化的时候通过alloc_desc函数为每个irq进行分配的。在alloc_desc中对irq_desc的初始化会把handle_irq函数指针默认初始化为handle_bad_irq，这个函数代表还没有中断控制器注册这个函数，handle_bad_irq只是简单地确认一下中断，然后做个错误记录。

中断控制器注册handle_irq函数的代码如下：
linux-src/kernel/irq/chip.c

```C
void
__irq_set_handler(unsigned int irq, irq_flow_handler_t handle, int is_chained,
                  const char *name)
{
        unsigned long flags;
        struct irq_desc *desc = irq_get_desc_buslock(irq, &flags, 0);

        if (!desc)
                return;

        __irq_do_set_handler(desc, handle, is_chained, name);
        irq_put_desc_busunlock(desc, flags);
}

static void
__irq_do_set_handler(struct irq_desc *desc, irq_flow_handler_t handle,
                     int is_chained, const char *name)
{
        if (!handle) {
                handle = handle_bad_irq;
        } else {
                struct irq_data *irq_data = &desc->irq_data;
#ifdef CONFIG_IRQ_DOMAIN_HIERARCHY
                /*
                 * With hierarchical domains we might run into a
                 * situation where the outermost chip is not yet set
                 * up, but the inner chips are there.  Instead of
                 * bailing we install the handler, but obviously we
                 * cannot enable/startup the interrupt at this point.
                 */
                while (irq_data) {
                        if (irq_data->chip != &no_irq_chip)
                                break;
                        /*
                         * Bail out if the outer chip is not set up
                         * and the interrupt supposed to be started
                         * right away.
                         */
                        if (WARN_ON(is_chained))
                                return;
                        /* Try the parent */
                        irq_data = irq_data->parent_data;
                }
#endif
                if (WARN_ON(!irq_data || irq_data->chip == &no_irq_chip))
                        return;
        }

        /* Uninstall? */
        if (handle == handle_bad_irq) {
                if (desc->irq_data.chip != &no_irq_chip)
                        mask_ack_irq(desc);
                irq_state_set_disabled(desc);
                if (is_chained)
                        desc->action = NULL;
                desc->depth = 1;
        }
        desc->handle_irq = handle;
        desc->name = name;

        if (handle != handle_bad_irq && is_chained) {
                unsigned int type = irqd_get_trigger_type(&desc->irq_data);

                /*
                 * We're about to start this interrupt immediately,
                 * hence the need to set the trigger configuration.
                 * But the .set_type callback may have overridden the
                 * flow handler, ignoring that we're dealing with a
                 * chained interrupt. Reset it immediately because we
                 * do know better.
                 */
                if (type != IRQ_TYPE_NONE) {
                        __irq_set_trigger(desc, type);
                        desc->handle_irq = handle;
                }

                irq_settings_set_noprobe(desc);
                irq_settings_set_norequest(desc);
                irq_settings_set_nothread(desc);
                desc->action = &chained_action;
                irq_activate_and_startup(desc, IRQ_RESEND);
        }
}
```

不同的系统有不同的中断控制器，其在启动初始化的时候都会去注册irq_desc的handle_irq函数。

下面我们再来看一下具体的硬件驱动应该如何注册自己设备的ISR：
linux-src/include/linux/interrupt.h

```C
static inline int __must_check
request_irq(unsigned int irq, irq_handler_t handler, unsigned long flags,
            const char *name, void *dev)
{
        return request_threaded_irq(irq, handler, NULL, flags, name, dev);
}
```

linux-src/kernel/irq/manage.c

```C
int request_threaded_irq(unsigned int irq, irq_handler_t handler,
                         irq_handler_t thread_fn, unsigned long irqflags,
                         const char *devname, void *dev_id);
```

驱动程序使用request_irq接口来注册自己的ISR，ISR就是运行在硬中断的，参数handler代表的就是ISR。request_irq又调用request_threaded_irq来实现自己。request_threaded_irq是用来创建中断线程的函数接口，其中有两个参数handler、thread_fn，都是函数指针，handler代表的是ISR，是进行中断预处理的，thread_fn代表的是要创建的中断线程的入口函数，是进行中断后处理的。中断线程的细节我们在5.5中断线程中再细讲。

我们再来总结一下外设中断的处理方式。外设中断的向量表条目都被统一设置到同一个函数common_interrupt。在函数common_interrupt中又会根据irq参数去一个类型为irq_desc的vector_irq数组中寻找其对应的irq_desc，并用irq_desc的handle_irq来处理这个中断。vector_irq数组是在系统启动时初始化的，每个irq_desc的handle_irq都是中断控制器初始化时设置的，handle_irq的处理是和中断控制器密切相关的。具体的硬件驱动会通过request_irq接口来注册ISR，每个ISR都会生成一个irqaction，这个irqaction会挂在irq_desc的链表上。这样中断发生时handle_irq就可以去执行与irq相对应的每个ISR了。


##   5.3 软中断(softirq)

软中断是把中断处理程序分成了两段：前一段叫做硬中断，执行驱动的ISR，处理与硬件密切相关的事，在此期间是禁止中断的；后一段叫做软中断，软中断中处理和硬件不太密切的事物，在此期间是开中断的，可以继续接受硬件中断。软中断的设计提高了系统对中断的响应性。下面我们先说软中断的执行时机，然后再说软中断的使用接口。

软中断也是中断处理程序的一部分，是在ISR执行完成之后运行的，在ISR中可以向软中断中添加任务，然后软中断有事要做就会运行了。除此之外软中断还有两个执行时机，一是当软中断过多，处理不过来的时候，会唤醒ksoftirqd/x线程来执行软中断；二是在禁用软中断临界区结束的时候，会检测有没有pending软中断要处理，如果有的话就会执行软中断。正宗的软中断执行时机是指跟在硬中断后面执行的软中断，我们把这个叫做直接软中断。一般情况下所说的软中断指的都是直接软中断，而不是ksoftirqd/x线程，不能把ksoftirqd/x线程等同于软中断，它只是辅助执行软中断的一个时机，没有它，软中断依然存在。

下面我们来看一下直接软中断的执行时机和它唤醒ksoftirqd/x线程的条件。
linux-src/kernel/irq/irqdesc.c

```C
int handle_domain_irq(struct irq_domain *domain,
                      unsigned int hwirq, struct pt_regs *regs)
{
        struct pt_regs *old_regs = set_irq_regs(regs);
        struct irq_desc *desc;
        int ret = 0;

        irq_enter();

        /* The irqdomain code provides boundary checks */
        desc = irq_resolve_mapping(domain, hwirq);
        if (likely(desc))
                handle_irq_desc(desc);
        else
                ret = -EINVAL;

        irq_exit();
        set_irq_regs(old_regs);
        return ret;
}
```

linux-src/kernel/softirq.c

```C
void irq_exit(void)
{
        __irq_exit_rcu();
        rcu_irq_exit();
         /* must be last! */
        lockdep_hardirq_exit();
}

static inline void __irq_exit_rcu(void)
{
#ifndef __ARCH_IRQ_EXIT_IRQS_DISABLED
        local_irq_disable();
#else
        lockdep_assert_irqs_disabled();
#endif
        account_hardirq_exit(current);
        preempt_count_sub(HARDIRQ_OFFSET);
        if (!in_interrupt() && local_softirq_pending())
                invoke_softirq();

        tick_irq_exit();
}

static inline void invoke_softirq(void)
{
        if (ksoftirqd_running(local_softirq_pending()))
                return;

        if (!force_irqthreads() || !__this_cpu_read(ksoftirqd)) {
#ifdef CONFIG_HAVE_IRQ_EXIT_ON_IRQ_STACK
                /*
                 * We can safely execute softirq on the current stack if
                 * it is the irq stack, because it should be near empty
                 * at this stage.
                 */
                __do_softirq();
#else
                /*
                 * Otherwise, irq_exit() is called on the task stack that can
                 * be potentially deep already. So call softirq in its own stack
                 * to prevent from any overrun.
                 */
                do_softirq_own_stack();
#endif
        } else {
                wakeup_softirqd();
        }
}

asmlinkage __visible void __softirq_entry __do_softirq(void)
{
        unsigned long end = jiffies + MAX_SOFTIRQ_TIME;
        unsigned long old_flags = current->flags;
        int max_restart = MAX_SOFTIRQ_RESTART;
        struct softirq_action *h;
        bool in_hardirq;
        __u32 pending;
        int softirq_bit;

        static int i = 0;
        if(++i == 50)
                dump_stack();

        /*
         * Mask out PF_MEMALLOC as the current task context is borrowed for the
         * softirq. A softirq handled, such as network RX, might set PF_MEMALLOC
         * again if the socket is related to swapping.
         */
        current->flags &= ~PF_MEMALLOC;

        pending = local_softirq_pending();

        softirq_handle_begin();
        in_hardirq = lockdep_softirq_start();
        account_softirq_enter(current);

restart:
        /* Reset the pending bitmask before enabling irqs */
        set_softirq_pending(0);

        local_irq_enable();

        h = softirq_vec;

        while ((softirq_bit = ffs(pending))) {
                unsigned int vec_nr;
                int prev_count;

                h += softirq_bit - 1;

                vec_nr = h - softirq_vec;
                prev_count = preempt_count();

                kstat_incr_softirqs_this_cpu(vec_nr);

                trace_softirq_entry(vec_nr);
                h->action(h);
                trace_softirq_exit(vec_nr);
                if (unlikely(prev_count != preempt_count())) {
                        pr_err("huh, entered softirq %u %s %p with preempt_count %08x, exited with %08x?\n",
                               vec_nr, softirq_to_name[vec_nr], h->action,
                               prev_count, preempt_count());
                        preempt_count_set(prev_count);
                }
                h++;
                pending >>= softirq_bit;
        }

        if (!IS_ENABLED(CONFIG_PREEMPT_RT) &&
            __this_cpu_read(ksoftirqd) == current)
                rcu_softirq_qs();

        local_irq_disable();

        pending = local_softirq_pending();
        if (pending) {
                if (time_before(jiffies, end) && !need_resched() &&
                    --max_restart)
                        goto restart;

                wakeup_softirqd();
        }

        account_softirq_exit(current);
        lockdep_softirq_end(in_hardirq);
        softirq_handle_end();
        current_restore_flags(old_flags, PF_MEMALLOC);
}
```

可以看到__do_softirq在执行软中断前会打开中断local_irq_enable()，在执行完软中断之后又会关闭中断local_irq_disable()。所以软中断执行期间CPU是可以接收硬件中断的。当把所有的软中断都处理一遍之后，如果还有pending的软中断要处理，此时会去唤醒ksoftirqd线程来执行软中断，除非此时系统没有触发被动调度而且软中断执行的次数和时间都比较少。

下面我们再来看一下软中断的使用接口。软中断定义了一个softirq_action类型的数组，数组大小是NR_SOFTIRQS，代表软中断的类型，目前只有10种软中断类型。softirq_action结构体里面仅仅只有一个函数指针。当我们要设置某一类软中断的处理函数时使用接口open_softirq。当我们想要触发某一类软中断的执行时使用接口raise_softirq。

下面我们来看一下代码：
linux-src/include/linux/interrupt.h

```C
enum
{
        HI_SOFTIRQ=0,
        TIMER_SOFTIRQ,
        NET_TX_SOFTIRQ,
        NET_RX_SOFTIRQ,
        BLOCK_SOFTIRQ,
        IRQ_POLL_SOFTIRQ,
        TASKLET_SOFTIRQ,
        SCHED_SOFTIRQ,
        HRTIMER_SOFTIRQ,
        RCU_SOFTIRQ,    /* Preferable RCU should always be the last softirq */

        NR_SOFTIRQS
};

struct softirq_action
{
        void        (*action)(struct softirq_action *);
};
```

linux-src/kernel/softirq.c

```C
static struct softirq_action softirq_vec[NR_SOFTIRQS] __cacheline_aligned_in_smp;

void open_softirq(int nr, void (*action)(struct softirq_action *))
{
        softirq_vec[nr].action = action;
}

void raise_softirq(unsigned int nr)
{
        unsigned long flags;

        local_irq_save(flags);
        raise_softirq_irqoff(nr);
        local_irq_restore(flags);
}

inline void raise_softirq_irqoff(unsigned int nr)
{
        __raise_softirq_irqoff(nr);

        /*
         * If we're in an interrupt or softirq, we're done
         * (this also catches softirq-disabled code). We will
         * actually run the softirq once we return from
         * the irq or softirq.
         *
         * Otherwise we wake up ksoftirqd to make sure we
         * schedule the softirq soon.
         */
        if (!in_interrupt() && should_wake_ksoftirqd())
                wakeup_softirqd();
}

void __raise_softirq_irqoff(unsigned int nr)
{
        lockdep_assert_irqs_disabled();
        trace_softirq_raise(nr);
        or_softirq_pending(1UL << nr);
}
```

所有软中断的处理函数都是在系统启动的初始化函数里面用open_softirq接口设置的。raise_softirq一般是在硬中断或者软中断中用来往软中断上push work使得软中断可以被触发执行或者继续执行。


##   5.4 微任务(tasklet)

新代码要想使用softirq就必须修改内核的核心代码，添加新的softirq类型，这对于很多驱动程序来说是做不到的，于是内核在softirq的基础上开发了tasklet。使用tasklet不需要修改内核的核心代码，驱动程序直接使用tasklet的接口就可以了。

Tasklet其实是一种特殊的softirq，它是在softirq的基础上进行了扩展。它利用的就是softirq中的HI_SOFTIRQ和TASKLET_SOFTIRQ。softirq在初始化的时候会设置这两个softirq类型。然后其处理函数会去处理tasklet的链表。我们在使用tasklet的时候只需要定义一个tasklet_struct，并用我们想要执行的函数初始化它，然后再用tasklet_schedule把它放入到队列中，它就会被执行了。下面我们来看一下代码：

linux-src/kernel/softirq.c

```C
void __init softirq_init(void)
{
        int cpu;

        for_each_possible_cpu(cpu) {
                per_cpu(tasklet_vec, cpu).tail =
                        &per_cpu(tasklet_vec, cpu).head;
                per_cpu(tasklet_hi_vec, cpu).tail =
                        &per_cpu(tasklet_hi_vec, cpu).head;
        }

        open_softirq(TASKLET_SOFTIRQ, tasklet_action);
        open_softirq(HI_SOFTIRQ, tasklet_hi_action);
}

static __latent_entropy void tasklet_action(struct softirq_action *a)
{
        tasklet_action_common(a, this_cpu_ptr(&tasklet_vec), TASKLET_SOFTIRQ);
}

static __latent_entropy void tasklet_hi_action(struct softirq_action *a)
{
        tasklet_action_common(a, this_cpu_ptr(&tasklet_hi_vec), HI_SOFTIRQ);
}

static void tasklet_action_common(struct softirq_action *a,
                                  struct tasklet_head *tl_head,
                                  unsigned int softirq_nr)
{
        struct tasklet_struct *list;

        local_irq_disable();
        list = tl_head->head;
        tl_head->head = NULL;
        tl_head->tail = &tl_head->head;
        local_irq_enable();

        while (list) {
                struct tasklet_struct *t = list;

                list = list->next;

                if (tasklet_trylock(t)) {
                        if (!atomic_read(&t->count)) {
                                if (tasklet_clear_sched(t)) {
                                        if (t->use_callback)
                                                t->callback(t);
                                        else
                                                t->func(t->data);
                                }
                                tasklet_unlock(t);
                                continue;
                        }
                        tasklet_unlock(t);
                }

                local_irq_disable();
                t->next = NULL;
                *tl_head->tail = t;
                tl_head->tail = &t->next;
                __raise_softirq_irqoff(softirq_nr);
                local_irq_enable();
        }
}

static DEFINE_PER_CPU(struct tasklet_head, tasklet_vec);
static DEFINE_PER_CPU(struct tasklet_head, tasklet_hi_vec);

static void __tasklet_schedule_common(struct tasklet_struct *t,
                                      struct tasklet_head __percpu *headp,
                                      unsigned int softirq_nr)
{
        struct tasklet_head *head;
        unsigned long flags;

        local_irq_save(flags);
        head = this_cpu_ptr(headp);
        t->next = NULL;
        *head->tail = t;
        head->tail = &(t->next);
        raise_softirq_irqoff(softirq_nr);
        local_irq_restore(flags);
}

void __tasklet_schedule(struct tasklet_struct *t)
{
        __tasklet_schedule_common(t, &tasklet_vec,
                                  TASKLET_SOFTIRQ);
}
EXPORT_SYMBOL(__tasklet_schedule);

void __tasklet_hi_schedule(struct tasklet_struct *t)
{
        __tasklet_schedule_common(t, &tasklet_hi_vec,
                                  HI_SOFTIRQ);
}
EXPORT_SYMBOL(__tasklet_hi_schedule);
```

linux-src/include/linux/interrupt.h

```C
static inline void tasklet_schedule(struct tasklet_struct *t)
{
        if (!test_and_set_bit(TASKLET_STATE_SCHED, &t->state))
                __tasklet_schedule(t);
}

static inline void tasklet_hi_schedule(struct tasklet_struct *t)
{
        if (!test_and_set_bit(TASKLET_STATE_SCHED, &t->state))
                __tasklet_hi_schedule(t);
}
```

Tasklet和softirq有一个很大的区别就是，同一个softirq可以在不同的CPU上并发执行，而同一个tasklet不会在多个CPU上并发执行。所以我们在编程的时候，如果使用的是tasklet就不用考虑多CPU之间的同步问题。

还有很重要的一点，tasklet不是独立的，它是softirq的一部分，禁用软中断的同时也禁用了tasklet。


##   5.5 中断线程(threaded_irq)

前面讲的硬中断，它是外设中断处理中必不可少的一部分。Softirq和tasklet虽然不会禁用中断，提高了系统对中断的响应性，但是softirq的执行优先级还是比进程的优先级高，有些确实不那么重要的任务其实可以放到进程里执行，和普通进程共同竞争CPU。而且软中断里不能调用会阻塞、休眠的函数，这对软中断函数的编程是很不利的，所以综合各种因素，我们需要把中断处理任务中的与硬件无关有不太紧急的部分放到进程里面来做。为此内核开发了两种方法，中断线程和工作队列。

我们这节先讲中断线程，其接口如下：
linux-src/include/linux/interrupt.h

```C
extern int __must_check
request_threaded_irq(unsigned int irq, irq_handler_t handler,
                     irq_handler_t thread_fn,
                     unsigned long flags, const char *name, void *dev);
```

如果我们要为某个外设注册中断处理程序，可以使用这个接口。其中handler是硬中断，是处理与硬件密切相关的事物。其处理完成后，可以把接收到的数据、要继续处理的事情放到某个位置，然后返回是否需要唤醒对应的中断线程。如果需要的话，系统会唤醒其对应的中断线程来继续处理任务，这个线程的主函数就是第三个参数thread_fn。下面我们来看一下这个接口的实现。

linux-src/kernel/irq/manage.c

```C
int request_threaded_irq(unsigned int irq, irq_handler_t handler,
                         irq_handler_t thread_fn, unsigned long irqflags,
                         const char *devname, void *dev_id)
{
        struct irqaction *action;
        struct irq_desc *desc;
        int retval;

        if (irq == IRQ_NOTCONNECTED)
                return -ENOTCONN;

        /*
         * Sanity-check: shared interrupts must pass in a real dev-ID,
         * otherwise we'll have trouble later trying to figure out
         * which interrupt is which (messes up the interrupt freeing
         * logic etc).
         *
         * Also shared interrupts do not go well with disabling auto enable.
         * The sharing interrupt might request it while it's still disabled
         * and then wait for interrupts forever.
         *
         * Also IRQF_COND_SUSPEND only makes sense for shared interrupts and
         * it cannot be set along with IRQF_NO_SUSPEND.
         */
        if (((irqflags & IRQF_SHARED) && !dev_id) ||
            ((irqflags & IRQF_SHARED) && (irqflags & IRQF_NO_AUTOEN)) ||
            (!(irqflags & IRQF_SHARED) && (irqflags & IRQF_COND_SUSPEND)) ||
            ((irqflags & IRQF_NO_SUSPEND) && (irqflags & IRQF_COND_SUSPEND)))
                return -EINVAL;

        desc = irq_to_desc(irq);
        if (!desc)
                return -EINVAL;

        if (!irq_settings_can_request(desc) ||
            WARN_ON(irq_settings_is_per_cpu_devid(desc)))
                return -EINVAL;

        if (!handler) {
                if (!thread_fn)
                        return -EINVAL;
                handler = irq_default_primary_handler;
        }

        action = kzalloc(sizeof(struct irqaction), GFP_KERNEL);
        if (!action)
                return -ENOMEM;

        action->handler = handler;
        action->thread_fn = thread_fn;
        action->flags = irqflags;
        action->name = devname;
        action->dev_id = dev_id;

        retval = irq_chip_pm_get(&desc->irq_data);
        if (retval < 0) {
                kfree(action);
                return retval;
        }

        retval = __setup_irq(irq, desc, action);

        if (retval) {
                irq_chip_pm_put(&desc->irq_data);
                kfree(action->secondary);
                kfree(action);
        }

#ifdef CONFIG_DEBUG_SHIRQ_FIXME
        if (!retval && (irqflags & IRQF_SHARED)) {
                /*
                 * It's a shared IRQ -- the driver ought to be prepared for it
                 * to happen immediately, so let's make sure....
                 * We disable the irq to make sure that a 'real' IRQ doesn't
                 * run in parallel with our fake.
                 */
                unsigned long flags;

                disable_irq(irq);
                local_irq_save(flags);

                handler(irq, dev_id);

                local_irq_restore(flags);
                enable_irq(irq);
        }
#endif
        return retval;
}

static int
__setup_irq(unsigned int irq, struct irq_desc *desc, struct irqaction *new)
{
        struct irqaction *old, **old_ptr;
        unsigned long flags, thread_mask = 0;
        int ret, nested, shared = 0;

        if (!desc)
                return -EINVAL;

        if (desc->irq_data.chip == &no_irq_chip)
                return -ENOSYS;
        if (!try_module_get(desc->owner))
                return -ENODEV;

        new->irq = irq;

        /*
         * If the trigger type is not specified by the caller,
         * then use the default for this interrupt.
         */
        if (!(new->flags & IRQF_TRIGGER_MASK))
                new->flags |= irqd_get_trigger_type(&desc->irq_data);

        /*
         * Check whether the interrupt nests into another interrupt
         * thread.
         */
        nested = irq_settings_is_nested_thread(desc);
        if (nested) {
                if (!new->thread_fn) {
                        ret = -EINVAL;
                        goto out_mput;
                }
                /*
                 * Replace the primary handler which was provided from
                 * the driver for non nested interrupt handling by the
                 * dummy function which warns when called.
                 */
                new->handler = irq_nested_primary_handler;
        } else {
                if (irq_settings_can_thread(desc)) {
                        ret = irq_setup_forced_threading(new);
                        if (ret)
                                goto out_mput;
                }
        }

        /*
         * Create a handler thread when a thread function is supplied
         * and the interrupt does not nest into another interrupt
         * thread.
         */
        if (new->thread_fn && !nested) {
                ret = setup_irq_thread(new, irq, false);
                if (ret)
                        goto out_mput;
                if (new->secondary) {
                        ret = setup_irq_thread(new->secondary, irq, true);
                        if (ret)
                                goto out_thread;
                }
        }

        /*
         * Drivers are often written to work w/o knowledge about the
         * underlying irq chip implementation, so a request for a
         * threaded irq without a primary hard irq context handler
         * requires the ONESHOT flag to be set. Some irq chips like
         * MSI based interrupts are per se one shot safe. Check the
         * chip flags, so we can avoid the unmask dance at the end of
         * the threaded handler for those.
         */
        if (desc->irq_data.chip->flags & IRQCHIP_ONESHOT_SAFE)
                new->flags &= ~IRQF_ONESHOT;

        /*
         * Protects against a concurrent __free_irq() call which might wait
         * for synchronize_hardirq() to complete without holding the optional
         * chip bus lock and desc->lock. Also protects against handing out
         * a recycled oneshot thread_mask bit while it's still in use by
         * its previous owner.
         */
        mutex_lock(&desc->request_mutex);

        /*
         * Acquire bus lock as the irq_request_resources() callback below
         * might rely on the serialization or the magic power management
         * functions which are abusing the irq_bus_lock() callback,
         */
        chip_bus_lock(desc);

        /* First installed action requests resources. */
        if (!desc->action) {
                ret = irq_request_resources(desc);
                if (ret) {
                        pr_err("Failed to request resources for %s (irq %d) on irqchip %s\n",
                               new->name, irq, desc->irq_data.chip->name);
                        goto out_bus_unlock;
                }
        }

        /*
         * The following block of code has to be executed atomically
         * protected against a concurrent interrupt and any of the other
         * management calls which are not serialized via
         * desc->request_mutex or the optional bus lock.
         */
        raw_spin_lock_irqsave(&desc->lock, flags);
        old_ptr = &desc->action;
        old = *old_ptr;
        if (old) {
                /*
                 * Can't share interrupts unless both agree to and are
                 * the same type (level, edge, polarity). So both flag
                 * fields must have IRQF_SHARED set and the bits which
                 * set the trigger type must match. Also all must
                 * agree on ONESHOT.
                 * Interrupt lines used for NMIs cannot be shared.
                 */
                unsigned int oldtype;

                if (desc->istate & IRQS_NMI) {
                        pr_err("Invalid attempt to share NMI for %s (irq %d) on irqchip %s.\n",
                                new->name, irq, desc->irq_data.chip->name);
                        ret = -EINVAL;
                        goto out_unlock;
                }

                /*
                 * If nobody did set the configuration before, inherit
                 * the one provided by the requester.
                 */
                if (irqd_trigger_type_was_set(&desc->irq_data)) {
                        oldtype = irqd_get_trigger_type(&desc->irq_data);
                } else {
                        oldtype = new->flags & IRQF_TRIGGER_MASK;
                        irqd_set_trigger_type(&desc->irq_data, oldtype);
                }

                if (!((old->flags & new->flags) & IRQF_SHARED) ||
                    (oldtype != (new->flags & IRQF_TRIGGER_MASK)) ||
                    ((old->flags ^ new->flags) & IRQF_ONESHOT))
                        goto mismatch;

                /* All handlers must agree on per-cpuness */
                if ((old->flags & IRQF_PERCPU) !=
                    (new->flags & IRQF_PERCPU))
                        goto mismatch;

                /* add new interrupt at end of irq queue */
                do {
                        /*
                         * Or all existing action->thread_mask bits,
                         * so we can find the next zero bit for this
                         * new action.
                         */
                        thread_mask |= old->thread_mask;
                        old_ptr = &old->next;
                        old = *old_ptr;
                } while (old);
                shared = 1;
        }

        /*
         * Setup the thread mask for this irqaction for ONESHOT. For
         * !ONESHOT irqs the thread mask is 0 so we can avoid a
         * conditional in irq_wake_thread().
         */
        if (new->flags & IRQF_ONESHOT) {
                /*
                 * Unlikely to have 32 resp 64 irqs sharing one line,
                 * but who knows.
                 */
                if (thread_mask == ~0UL) {
                        ret = -EBUSY;
                        goto out_unlock;
                }
                /*
                 * The thread_mask for the action is or'ed to
                 * desc->thread_active to indicate that the
                 * IRQF_ONESHOT thread handler has been woken, but not
                 * yet finished. The bit is cleared when a thread
                 * completes. When all threads of a shared interrupt
                 * line have completed desc->threads_active becomes
                 * zero and the interrupt line is unmasked. See
                 * handle.c:irq_wake_thread() for further information.
                 *
                 * If no thread is woken by primary (hard irq context)
                 * interrupt handlers, then desc->threads_active is
                 * also checked for zero to unmask the irq line in the
                 * affected hard irq flow handlers
                 * (handle_[fasteoi|level]_irq).
                 *
                 * The new action gets the first zero bit of
                 * thread_mask assigned. See the loop above which or's
                 * all existing action->thread_mask bits.
                 */
                new->thread_mask = 1UL << ffz(thread_mask);

        } else if (new->handler == irq_default_primary_handler &&
                   !(desc->irq_data.chip->flags & IRQCHIP_ONESHOT_SAFE)) {
                /*
                 * The interrupt was requested with handler = NULL, so
                 * we use the default primary handler for it. But it
                 * does not have the oneshot flag set. In combination
                 * with level interrupts this is deadly, because the
                 * default primary handler just wakes the thread, then
                 * the irq lines is reenabled, but the device still
                 * has the level irq asserted. Rinse and repeat....
                 *
                 * While this works for edge type interrupts, we play
                 * it safe and reject unconditionally because we can't
                 * say for sure which type this interrupt really
                 * has. The type flags are unreliable as the
                 * underlying chip implementation can override them.
                 */
                pr_err("Threaded irq requested with handler=NULL and !ONESHOT for %s (irq %d)\n",
                       new->name, irq);
                ret = -EINVAL;
                goto out_unlock;
        }

        if (!shared) {
                init_waitqueue_head(&desc->wait_for_threads);

                /* Setup the type (level, edge polarity) if configured: */
                if (new->flags & IRQF_TRIGGER_MASK) {
                        ret = __irq_set_trigger(desc,
                                                new->flags & IRQF_TRIGGER_MASK);

                        if (ret)
                                goto out_unlock;
                }

                /*
                 * Activate the interrupt. That activation must happen
                 * independently of IRQ_NOAUTOEN. request_irq() can fail
                 * and the callers are supposed to handle
                 * that. enable_irq() of an interrupt requested with
                 * IRQ_NOAUTOEN is not supposed to fail. The activation
                 * keeps it in shutdown mode, it merily associates
                 * resources if necessary and if that's not possible it
                 * fails. Interrupts which are in managed shutdown mode
                 * will simply ignore that activation request.
                 */
                ret = irq_activate(desc);
                if (ret)
                        goto out_unlock;

                desc->istate &= ~(IRQS_AUTODETECT | IRQS_SPURIOUS_DISABLED | \
                                  IRQS_ONESHOT | IRQS_WAITING);
                irqd_clear(&desc->irq_data, IRQD_IRQ_INPROGRESS);

                if (new->flags & IRQF_PERCPU) {
                        irqd_set(&desc->irq_data, IRQD_PER_CPU);
                        irq_settings_set_per_cpu(desc);
                        if (new->flags & IRQF_NO_DEBUG)
                                irq_settings_set_no_debug(desc);
                }

                if (noirqdebug)
                        irq_settings_set_no_debug(desc);

                if (new->flags & IRQF_ONESHOT)
                        desc->istate |= IRQS_ONESHOT;

                /* Exclude IRQ from balancing if requested */
                if (new->flags & IRQF_NOBALANCING) {
                        irq_settings_set_no_balancing(desc);
                        irqd_set(&desc->irq_data, IRQD_NO_BALANCING);
                }

                if (!(new->flags & IRQF_NO_AUTOEN) &&
                    irq_settings_can_autoenable(desc)) {
                        irq_startup(desc, IRQ_RESEND, IRQ_START_COND);
                } else {
                        /*
                         * Shared interrupts do not go well with disabling
                         * auto enable. The sharing interrupt might request
                         * it while it's still disabled and then wait for
                         * interrupts forever.
                         */
                        WARN_ON_ONCE(new->flags & IRQF_SHARED);
                        /* Undo nested disables: */
                        desc->depth = 1;
                }

        } else if (new->flags & IRQF_TRIGGER_MASK) {
                unsigned int nmsk = new->flags & IRQF_TRIGGER_MASK;
                unsigned int omsk = irqd_get_trigger_type(&desc->irq_data);

                if (nmsk != omsk)
                        /* hope the handler works with current  trigger mode */
                        pr_warn("irq %d uses trigger mode %u; requested %u\n",
                                irq, omsk, nmsk);
        }

        *old_ptr = new;

        irq_pm_install_action(desc, new);

        /* Reset broken irq detection when installing new handler */
        desc->irq_count = 0;
        desc->irqs_unhandled = 0;

        /*
         * Check whether we disabled the irq via the spurious handler
         * before. Reenable it and give it another chance.
         */
        if (shared && (desc->istate & IRQS_SPURIOUS_DISABLED)) {
                desc->istate &= ~IRQS_SPURIOUS_DISABLED;
                __enable_irq(desc);
        }

        raw_spin_unlock_irqrestore(&desc->lock, flags);
        chip_bus_sync_unlock(desc);
        mutex_unlock(&desc->request_mutex);

        irq_setup_timings(desc, new);

        /*
         * Strictly no need to wake it up, but hung_task complains
         * when no hard interrupt wakes the thread up.
         */
        if (new->thread)
                wake_up_process(new->thread);
        if (new->secondary)
                wake_up_process(new->secondary->thread);

        register_irq_proc(irq, desc);
        new->dir = NULL;
        register_handler_proc(irq, new);
        return 0;

mismatch:
        if (!(new->flags & IRQF_PROBE_SHARED)) {
                pr_err("Flags mismatch irq %d. %08x (%s) vs. %08x (%s)\n",
                       irq, new->flags, new->name, old->flags, old->name);
#ifdef CONFIG_DEBUG_SHIRQ
                dump_stack();
#endif
        }
        ret = -EBUSY;

out_unlock:
        raw_spin_unlock_irqrestore(&desc->lock, flags);

        if (!desc->action)
                irq_release_resources(desc);
out_bus_unlock:
        chip_bus_sync_unlock(desc);
        mutex_unlock(&desc->request_mutex);

out_thread:
        if (new->thread) {
                struct task_struct *t = new->thread;

                new->thread = NULL;
                kthread_stop(t);
                put_task_struct(t);
        }
        if (new->secondary && new->secondary->thread) {
                struct task_struct *t = new->secondary->thread;

                new->secondary->thread = NULL;
                kthread_stop(t);
                put_task_struct(t);
        }
out_mput:
        module_put(desc->owner);
        return ret;
}

static int
setup_irq_thread(struct irqaction *new, unsigned int irq, bool secondary)
{
        struct task_struct *t;

        if (!secondary) {
                t = kthread_create(irq_thread, new, "irq/%d-%s", irq,
                                   new->name);
        } else {
                t = kthread_create(irq_thread, new, "irq/%d-s-%s", irq,
                                   new->name);
        }

        if (IS_ERR(t))
                return PTR_ERR(t);

        sched_set_fifo(t);

        /*
         * We keep the reference to the task struct even if
         * the thread dies to avoid that the interrupt code
         * references an already freed task_struct.
         */
        new->thread = get_task_struct(t);
        /*
         * Tell the thread to set its affinity. This is
         * important for shared interrupt handlers as we do
         * not invoke setup_affinity() for the secondary
         * handlers as everything is already set up. Even for
         * interrupts marked with IRQF_NO_BALANCE this is
         * correct as we want the thread to move to the cpu(s)
         * on which the requesting code placed the interrupt.
         */
        set_bit(IRQTF_AFFINITY, &new->thread_flags);
        return 0;
}
```

中断线程虽然实现很复杂，但是其使用接口还是很简单的。


##   5.6 工作队列(workqueue)

工作队列是内核中使用最广泛的线程化中断处理机制。系统中有一些默认的工作队列，你也可以创建自己的工作队列，工作队列背后对应的是内核线程。你可以创建一个work，然后push到某个工作队列，然后这个工作队列背后的内核线程就会去执行这些work。下面我们来看一下工作队列的接口。

linux-src/include/linux/workqueue.h

```C
struct work_struct {
        atomic_long_t data;
        struct list_head entry;
        work_func_t func;
#ifdef CONFIG_LOCKDEP
        struct lockdep_map lockdep_map;
#endif
};

#define DECLARE_WORK(n, f)                                                \
        struct work_struct n = __WORK_INITIALIZER(n, f)

#define __WORK_INITIALIZER(n, f) {                                        \
        .data = WORK_DATA_STATIC_INIT(),                                \
        .entry        = { &(n).entry, &(n).entry },                                \
        .func = (f),                                                        \
        __WORK_INIT_LOCKDEP_MAP(#n, &(n))                                \
        }

static inline bool schedule_work(struct work_struct *work)
{
        return queue_work(system_wq, work);
}

static inline bool schedule_work_on(int cpu, struct work_struct *work)
{
        return queue_work_on(cpu, system_wq, work);
}
```

这是创建work，把work push到系统默认的工作队列上的接口，下面我们再来看一下创建自己的工作队列的接口：
linux-src/include/linux/workqueue.h

```C
struct workqueue_struct *
alloc_workqueue(const char *fmt, unsigned int flags, int max_active, ...);

#define create_workqueue(name)                                                \
        alloc_workqueue("%s", __WQ_LEGACY | WQ_MEM_RECLAIM, 1, (name))
```

工作队列还有很多很丰富的接口，这里就不一一介绍了。

关于工作队列的实现原理，推荐阅读：
[http://www.wowotech.net/irq_subsystem/workqueue.html](http://www.wowotech.net/irq_subsystem/workqueue.html)
[http://www.wowotech.net/irq_subsystem/cmwq-intro.html](http://www.wowotech.net/irq_subsystem/cmwq-intro.html)
[http://www.wowotech.net/irq_subsystem/alloc_workqueue.html](http://www.wowotech.net/irq_subsystem/alloc_workqueue.html)
[http://www.wowotech.net/irq_subsystem/queue_and_handle_work.html](http://www.wowotech.net/irq_subsystem/queue_and_handle_work.html)


#   六、中断与同步

在只有线程的情况下，线程之间的同步逻辑还是很好理解的，但是有了中断之后，硬中断、软中断、线程相互之间的同步就变得复杂起来。下面我们就来看一下它们在运行的时候相互之间的抢占关系。


##   6.1 CPU运行模型

首先我们来看一下CPU最原始的运行模型，图灵机模型，非常简单，就是一条直线一直运行下去。

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/V5wabFDPioNlUNxMjUict8esn2c.png)


在图灵机上加入中断之后，CPU的运行模型也是比较简单的。但是当我们考虑软件中断、硬件中断的区别时，CPU运行模型就开始变得复杂起来了。

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/J7Q7bsD1DoAoMbxDKcfc6LCvnzh.png)


不同的中断类型使得中断执行流有了不同的类型，这里一共分为三种类型，系统调用、CPU异常、硬件中断。现在这个还不算复杂，下面我们看一下它们之间的抢占情形。

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/BXDqb05LtoGXvVxjf1rcUq9snEh.png)


在系统调用时会发生CPU异常，也可能会发生硬件中断，在CPU异常的时候也可能发生硬件中断。其实这三者也可以嵌套起来，请看下图：

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/EG0zbU9aaoD0c0xF2P8cDga7nYb.png)


系统调用时发生了CPU异常，CPU异常时发生了硬件中断。下面我们把硬件中断的处理过程分为硬中断和软中断两部分，看看它们之间的关系。

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/H27Bb5Joxo6h2axqZojcOXzYnMb.png)


硬件中断的前半部分是硬中断，后半部分是软中断，硬中断中不能再嵌套硬中断了，但是软中断中可以嵌套硬中断。不过嵌套的硬中断在返回时发现正在执行软中断，就不会再重新还行软中断了，而是会回到原来的软中断执行流中。软中断的执行还有一种情况，如下图所示：

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/VKbTbG1Vnov15vxVQTccVVK9nYA.png)


这是因为线程在其临界区中禁用了软中断，如果临界区中发生了硬中断还是会执行的，但是硬中断返回时不会去执行软中断，因为软中断被禁用了。当线程的临界区结束是会再打开软中断，此时发现有pending的软中断没有处理，就会去执行软中断。



还有一种比较特殊的情况，就是线程里套软中断，软中断里套硬中断，硬中断里套NMI中断，如下图所示：

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/HwxJbT2b9ooDLyxTZricdr76nBe.png)


首先软中断是不能独立触发的，必须是硬中断触发软中断。在图中，第一个硬中断是执行完成了的，然后在软中断的执行过程中又发生了硬中断，第二个硬中断还没执行完的时候在执行过程中的时候又发生了NMI中断。这样就发生了四个不同等级的执行流一一嵌套的情况，这也是队列自旋锁的锁节点为啥要乘以4的原因。




##   6.2 中断相关同步方法

软中断可以抢占线程，硬中断可以抢占软中断也可以抢占线程，而返回来则不能抢占，所以如果我们的低等级执行流代码和高等级执行流代码有同步问题的话，就要考虑禁用高等级执行流。下面我们来看一下它们的接口，首先看禁用硬中断：

linux-src/include/linux/irqflags.h

```C
#define local_irq_enable()        do { raw_local_irq_enable(); } while (0)
#define local_irq_disable()        do { raw_local_irq_disable(); } while (0)
#define local_irq_save(flags)        do { raw_local_irq_save(flags); } while (0)
#define local_irq_restore(flags) do { raw_local_irq_restore(flags); } while (0)
```

linux-src/include/linux/interrupt.h

```C
extern void disable_irq_nosync(unsigned int irq);
extern bool disable_hardirq(unsigned int irq);
extern void disable_irq(unsigned int irq);
extern void disable_percpu_irq(unsigned int irq);
extern void enable_irq(unsigned int irq);
extern void enable_percpu_irq(unsigned int irq, unsigned int type);
```

你可以在一个CPU上禁用所有中断，也可以在所有CPU上禁用某个硬件中断，但是你不能在所有CPU上同时禁用所有硬件中断。

再来看一下禁用软中断的接口：
linux-src/include/linux/bottom_half.h

```C
static inline void local_bh_disable(void)
{
        __local_bh_disable_ip(_THIS_IP_, SOFTIRQ_DISABLE_OFFSET);
}

static inline void local_bh_enable(void)
{
        __local_bh_enable_ip(_THIS_IP_, SOFTIRQ_DISABLE_OFFSET);
}
```

我们只能禁用本地CPU的软中断，而且是整体禁用，不能只禁用某一类型的软中断。虽然在Linux中，下半部bh包括所有的下半部，但是此处的bh仅仅指软中断(包括tasklet)，不包括中断线程和工作队列。


#   七、总结回顾

本文我们从中断的概念开始讲起，一路上分析了中断的作用、中断的产生、中断的处理。其中内容最多的是硬件中断的处理，方法很多很繁杂。从6.1节CPU运行模型中，我们可以看到中断对于推动整个系统运行的重要性。所以说中断机制是计算机系统的神经和脉搏，一点都不为过。想要学会Linux内核，弄明白中断机制是其中必不可少的一环。最后我们再来看一下中断机制的图：

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/OKSeb584BoAzltxTQkrcl62VnFe.png)




**参考文献：**



《Linux Kernel Development》
《Understanding the Linux Kernel》
《Professional Linux Kernel Architecture》
《Intel® 64 and IA-32 Architectures Software Developer’s Manual Volume 3》
《Interrupt in Linux (硬件篇)》

[http://www.wowotech.net/sort/irq_subsystem](http://www.wowotech.net/sort/irq_subsystem)



   

显示推荐内容

