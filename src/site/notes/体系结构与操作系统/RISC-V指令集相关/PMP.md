---
{"dg-publish":true,"permalink":"/体系结构与操作系统/RISC-V指令集相关/PMP/","dgPassFrontmatter":true}
---


# PMP

1. 每个HART都有它自己的PMP寄存器，因此PMP寄存器的内存访问范围仅限于当前的HART
1. PMP也会影响MMIO的物理内存

PMP checks are applied to all accesses whose effective privilege mode is S or U, including instruction fetches and data accesses in S and U mode, and data accesses in M-mode when the MPRV bit in mstatus is set and the MPP field in mstatus contains S or U. PMP checks are also applied to page-table accesses for virtual-address translation, for which the effective privilege mode is S. Optionally, PMP checks may additionally apply to M-mode accesses, in which case the PMP registers themselves are locked, so that even M-mode software cannot change them until the hart is reset.

# 如何设置PMP？

我们在想设置一段物理内存受保护的时候，需要知道哪些信息呢？必要的当然有起始物理地址、空间范围、以及权限等。因此在设置PMP的时候，就需要读写PMPCFG寄存器和PMPADDR寄存器。其中前者用于设置权限等信息，后者用于设置起始物理地址。

在每个PMPCFG寄存器都有8组配置信息（32bit的机器有4组），每组配置信息占8bit，用于存储权限等信息，每组配置信息与一个PMPADDR一一对应。因此在64bit的机器下，一个PMPCFG寄存器与8个PMPADDR寄存器对应（在32bit的机器下是对应4个）。

一般地，一个HART提供了64个PMPADDR寄存器（编号从0到63），8个PMPCFG寄存器（在32bit的机器下是16个）。在32位的机器下，这16个PMPCFG寄存器的编号是从0到15，在64位的机器下，这8个PMPCFG寄存器的编号是`0, 2, 4, ..., 14`。这样做的目的是方便编程。

# PMPCFG寄存器

在RV64下，一个PMPCFG有8组配置信息：

![](https://cdn.jsdelivr.net/gh/wangzhankun/img-repo/QhyZbFGV8o4nDyxY2sTctOfmnqh.png)

每组配置信息：

![](https://cdn.jsdelivr.net/gh/wangzhankun/img-repo/KWy6bU8A8oqwojx69HPc9qfmnyd.png)

其中RWX分别表示可读、可写、可执行。

我们观察到，一个PMPCFG寄存器有8组配置信息，我们又知道，一组配置信息对应一个PMPADDR，PMPADDR一共有64个，因此为了方便PMPADDR与配置信息的对应关系，我们又将各组配置信息从0到63进行编号，分别称之为`pmp0cfg, pmp1cfg, ..., pmp63cfg`。其中`pmpicfg`对应`PMPADDRi`。

## A字段

`pmpicfg`中的A字段是用于Address Matching的，当A取不同的值时，`pmpaddr`寄存器的值的含义也会发生相应的变化。`A`字段可取的值有OFF, TOR, NA4和NAPOT，当值为NA4和NAPOT时，pmpaddr的含义如下所示。其中`yyyy...yy`的含义是物理起始地址，当末尾的值不同时，所表示的范围也不同。例如当`pmpaddr=yyyy...yyyy`且`A=NA4`时表示以`yyyy....yyyy`为起始地址的4个字节。

![](https://cdn.jsdelivr.net/gh/wangzhankun/img-repo/XW0BbpCweo6JDix5uEYc5MR1nrg.png)



但是当`A=TOR`时，情况有所不同，物理地址范围不再是由一个pmpaddr寄存器就能确定的了，而是两个pmpaddr。例如当`pmpicfg.A=TOR`时，那么受到保护的物理地址范围就是$pmpaddr_{i-1} \le y <pmpaddr_i$，此时会忽略$pmp_{i-1}cfg$的值。假如说这里的`i=0`，那么就表示$y<pmpaddr_0$的所有物理内存都受到保护。

## L字段

If PMP entry i is locked, writes to pmpicfg and pmpaddri are ignored. Additionally, if PMP entry i is locked and pmpicfg.A is set to TOR, writes to pmpaddri-1 are ignored.

## 优先级

PMP entries are statically prioritized. The lowest-numbered PMP entry that matches any byte of an access determines whether that access succeeds or fails. The matching PMP entry must match all bytes of an access, or the access fails, irrespective of the L, R, W, and X bits. For example, if a PMP entry is configured to match the four-byte range 0xC–0xF, then an 8-byte access to the range 0x8–0xF will fail, assuming that PMP entry is the highest-priority entry that matches those addresses.

If no PMP entry matches an M-mode access, the access succeeds. If no PMP entry matches an S-mode or U-mode access, but at least one PMP entry is implemented, the access fails.

