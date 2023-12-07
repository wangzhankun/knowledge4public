---
{"dg-publish":true,"permalink":"/体系结构与操作系统/RISC-V指令集相关/RISC-V ACLINT/","dgPassFrontmatter":true}
---


# RISC-V ACLINT

# RISC-V Advanced Core Local Interruptor Specification 
RISC-V 

|Warning |Assume everything can change. This draft specification will change before being accepted as standard, so implementations made to this draft specification will likely not conform to the future standard. 假设一切都可以改变。该规范草案在被接受为标准之前会发生变化，因此对该规范草案的实施可能不符合未来的标准。 |
|---|---|


## 1. Introduction

This RISC-V ACLINT specification defines a set of memory mapped devices which provide inter-processor interrupts (IPI) and timer functionalities for each HART on a multi-HART RISC-V platform. These HART-level IPI and timer functionalities are required by operating systems, bootloaders and firmwares running on a multi-HART RISC-V platform. 
此 RISC-V ACLINT 规范定义了一组内存映射设备，这些设备为多 HART RISC-V 平台上的每个 HART 提供处理器间中断 (IPI) 和定时器功能。在多 HART RISC-V 平台上运行的操作系统、引导加载程序和固件需要这些 HART 级 IPI 和计时器功能。



The SiFive Core-Local Interruptor (CLINT) device has been widely adopted in the RISC-V world to provide machine-level IPI and timer functionalities. Unfortunately, the SiFive CLINT has a unified register map for both IPI and timer functionalities and it does not provide supervisor-level IPI functionality. 
SiFive 核心本地中断器 (CLINT) 设备已在 RISC-V 世界中广泛采用，以提供M-mode IPI 和定时器功能。不幸的是，SiFive CLINT 具有用于 IPI 和定时器功能的统一寄存器映射（这导致IPI和定时器功能是绑定的，无法单独实现），并且它不提供S级 IPI 功能。



The RISC-V ACLINT specification takes a more modular approach by defining separate memory mapped devices for IPI and timer functionalities. This modularity allows RISC-V platforms to omit some of the RISC-V ACLINT devices for when the platform has an alternate mechanism. In addition to modularity, the RISC-V ACLINT specification also defines a dedicated memory mapped device for supervisor-level IPIs. The Table 1 below shows the list of devices defined by the RISC-V ACLINT specification. 
RISC-V ACLINT 规范采用更加模块化的方法为 IPI 和计时器功能定义单独的内存映射设备。这种模块化允许 RISC-V 平台在平台具有替代机制时省略一些 RISC-V ACLINT 设备。除了模块化之外，RISC-V ACLINT 规范还为S-mode  IPI 定义了专用的内存映射设备。下面的表 1 显示了 RISC-V ACLINT 规范定义的设备列表。



Table 1. ACLINT Devices  

|Name |Privilege Level |Functionality |
|---|---|---|
|MTIMER |Machine |Fixed-frequency counter and timer events  |
|MSWI |Machine |Inter-processor (or software) interrupts  |
|SSWI |Supervisor |Inter-processor (or software) interrupts  |
### 1.1. Backward Compatibility With SiFive CLINT 

The RISC-V ACLINT specification is defined to be backward compatible with the SiFive CLINT specification. The register definitions and register offsets of the MTIMER and MSWI devices are compatible with the timer and IPI registers defined by the SiFive CLINT specification. A SiFive CLINT device on a RISC-V platform can be logically seen as one MSWI device and one MTIMER devices placed next to each other in the memory address space as shown in Table 2 below. 
RISC-V ACLINT 规范向后兼容 SiFive CLINT 规范。 MTIMER 和 MSWI 设备的寄存器定义和寄存器偏移量与 SiFive CLINT 规范定义的定时器和 IPI 寄存器兼容。 RISC-V 平台上的一个 SiFive CLINT 设备在逻辑上可以看作是一个 MSWI 设备和一个 MTIMER 设备在内存地址空间中并排放置，如下表 2 所示。



Table 2. One SiFive CLINT device is equivalent to two ACLINT devices 

|SiFive CLINT Offset Range   |ACLINT Device |Functionality |
|---|---|---|
|0x0000_0000 - 0x0000_3fff  |MSWI |Machine-level inter-processor (or software) interrupts  |
|0x0000_4000 - 0x0000_bfff  |MTIMER |Machine-level fixed-frequency counter and timer events  |
## 2. Machine-level Timer Device (MTIMER) 

The MTIMER device provides machine-level timer functionality for a set of HARTs on a RISC-V platform. It has a single fixed-frequency monotonic time counter ( **MTIME**) register and a time compare register ( **MTIMECMP**) for each HART connected to the MTIMER device. A MTIMER device not connected to any HART should only have a MTIME register and no MTIMECMP registers. 
MTIMER 设备为 RISC-V 平台上的一组 HART 提供M-mode计时器功能。对于连接到 MTIMER 设备的每个 HART，它都有一个固定频率单调时间计数器 (MTIME) 寄存器和一个时间比较寄存器 (MTIMECMP)。未连接到任何 HART 的 MTIMER 设备应该只有一个 MTIME 寄存器而没有 MTIMECMP 寄存器。



On a RISC-V platform with multiple MTIMER devices: 
在具有多个 MTIMER 设备的 RISC-V 平台上：

* Each MTIMER device provides machine-level timer functionality for a different (or disjoint) set of HARTs. A MTIMER device assigns a HART index starting from zero to each HART associated with it. The HART index assigned to a HART by the MTIMER device may or may not have any relationship with the unique HART identifier ( **hart ID**) that the RISC-V Privileged Architecture assigns to the HART. 
每个 MTIMER 设备为一组不同的（或不相交的）HART 提供M-mode定时器功能。 MTIMER 设备从零开始为与其关联的每个 HART 分配一个 HART 索引。 MTIMER 设备分配给 HART 的 HART 索引可能与 RISC-V 特权架构分配给 HART 的唯一 HART 标识符（hart ID）有任何关系，也可能没有任何关系。
* Two or more MTIMER devices can share the same physical MTIME register while having their own separate MTIMECMP registers. 
两个或多个 MTIMER 设备可以共享同一个物理 MTIME 寄存器，但是 MTIMECMP 寄存器是各自独立拥有的。
* The MTIMECMP registers of a MTIMER device must only compare against the MTIME register of the same MTIMER device for generating machine-level timer interrupt. 
MTIMER 设备的 MTIMECMP 寄存器必须仅与同一 MTIMER 设备的 MTIME 寄存器进行比较以生成M-mode定时器中断。

The maximum number of HARTs supported by a single MTIMER device is 4095 which is equivalent to the maximum number of MTIMECMP registers. 
单个 MTIMER 设备支持的最大 HART 数量为 4095，相当于 MTIMECMP 寄存器的最大数量。

### 2.1. Register Map 

A MTIMER device has two separate base addresses: one for the MTIME register and another for the MTIMECMP registers. These separate base addresses of a single MTIMER device allows multiple MTIMER devices to share the same physical MTIME register. 
MTIMER 设备有两个独立的基地址：一个用于 MTIME 寄存器，另一个用于 MTIMECMP 寄存器。单个 MTIMER 设备的这些独立基地址允许多个 MTIMER 设备共享同一个物理 MTIME 寄存器。

The Table 3 below shows map of the MTIME register whereas the Table 4 below shows map of the MTIMECMP registers relative to separate base addresses. 
下面的表 3 显示了 MTIME 寄存器的映射，而下面的表 4 显示了 MTIMECMP 寄存器相对于单独基地址的映射。

Table 3. ACLINT MTIMER Time Register Map 
表 3. ACLINT MTIMER 时间寄存器映射

|Offset |Width |Attr |Name |Description |
|---|---|---|---|---|
|0x0000_0000 |8B |RW |MTIME |Machine-level time counter   |
Table 4. ACLINT MTIMER Compare Register Map 
表 4. ACLINT MTIMER 比较寄存器映射

|Offset |Width |Attr |Name |Description |
|---|---|---|---|---|
|0x0000_0000 |8B |RW |MTIMECMP0 |HART index 0 machine-level time compare  |
|0x0000_0008 |8B |RW |MTIMECMP1 |HART index 1 machine-level time compare  |
|… |… |… |… |… |
|0x0000_7FF0 |8B |RW |MTIMECMP4094 |HART index 4094 machine-level time compare  |
### 2.2. MTIME Register (Offset: 0x00000000) 

The MTIME register is a 64-bit read-write register that contains the number of cycles counted based on a fixed reference frequency. 
MTIME 寄存器是一个 64 位可读写寄存器，其中包含若干个周期数，每个周期都有固定的频率。



On MTIMER device reset, the MTIME register is cleared to zero. 
在 MTIMER 设备复位时，MTIME 寄存器被清零。



### 2.3. MTIMECMP Registers (Offsets: 0x00000000 - 0x00007FF0) 

The MTIMECMP registers are per-HART 64-bit read-write registers. It contains the MTIME register value at which machine-level timer interrupt is to be triggered for the corresponding HART. 
MTIMECMP 寄存器是符合 HART 标准的 64 位读写寄存器。它包含 MTIME 寄存器值，该值将为相应的 HART 触发M-mode定时器中断。



The machine-level timer interrupt of a HART is pending whenever MTIME is greater than or equal to the value in the corresponding MTIMECMP register whereas the machine-level timer interrupt of a HART is cleared whenever MTIME is less than the value of the corresponding MTIMECMP register. The machine-level timer interrupt is reflected in the MTIP bit of the `mip` CSR. 
只要 MTIME 大于或等于相应的 MTIMECMP 寄存器中的值，HART 的M-mode定时器中断就会挂起，而只要 MTIME 小于相应的 MTIMECMP 寄存器中的值，HART 的M-mode定时器中断就会被清除.M-mode定时器中断反映在 `mip` 寄存器的MTIP位。



On MTIMER device reset, the MTIMECMP registers are in unknown state. 
在 MTIMER 设备复位时，MTIMECMP 寄存器处于未知状态。



### 2.4. Synchronizing Multiple MTIME Registers 

A RISC-V platform can have multiple HARTs grouped into hierarchical topology groups (such as clusters, nodes, or sockets) where each topology group has it’s own MTIMER device. Further, such RISC-V platforms can also allow clock-gating or powering off for a topology group (including the MTIMER device) at runtime. 
RISC-V平台可以将多个HART分组成层次结构的拓扑组（如集群、节点或插座），其中每个拓扑组都有自己的MTIMER设备。此外，这样的RISC-V平台还可以在运行时为拓扑组（包括MTIMER设备）实现时钟门控或关闭电源的功能。



On a RISC-V platform with multiple MTIMER devices residing on the same die, each device must satisfy the RISC-V architectural requirement that all the MTIME registers with respect to each other, and all the per-HART `time` CSRs with respect to each other, are synchronized to within one MTIME tick period. For example, if the MTIME tick period is 10ns, then the MTIME registers, and their associated time CSRs, should respectively be synchronized to within 10ns of each other. 
在一个基于 RISC-V 架构的平台上，如果存在多个 MTIMER 设备位于同一芯片上，则每个设备都必须满足 RISC-V 架构的要求：所有的 MTIME 寄存器和每个 HART 的时间 CSRs 必须相互同步，并且彼此之间的偏差不得超过一个 MTIME tick 周期。例如，如果 MTIME tick 周期为10ns，则所有的 MTIME 寄存器和它们关联的时间 CSRs 应该在彼此之间同步，相互之间的最大偏差应不超过 10ns。



On a RISC-V platform with multiple MTIMER devices on different die, the MTIME registers (and their associated `time` CSRs) on different die may be synchronized to only within a specified interval of each other that is larger than the MTIME tick period. A platform may define a maximum allowed interval. 
在一个基于 RISC-V 架构的平台上，如果存在多个位于不同芯片上的 MTIMER（计时器）设备，则不同芯片上的 MTIME 寄存器（及其关联的时间 CSRs）可能仅在彼此之间的特定时间间隔内进行同步，而这个时间间隔可以大于 MTIME tick 周期。平台可以定义最大允许的时间间隔。



To satisfy the preceding MTIME synchronization requirements: 
要满足前面的 MTIME 同步要求：

* All MTIME registers should have the same input clock so as to avoid runtime drift between separate MTIME registers (and their associated `time` CSRs) 
所有 MTIME 寄存器应具有相同的输入时钟，以避免单独的 MTIME 寄存器（及其关联的 `time` CSR）之间的运行时漂移
* Upon system reset, the hardware must initialize and synchronize all MTIME registers to zero 
系统复位时，硬件必须初始化所有 MTIME 寄存器并将其同步为零
* When a MTIMER device is stopped and started again due to, say, power management actions, the software should re-synchronize this MTIME register with all other MTIME registers 
当 MTIMER 设备由于电源管理操作而停止并再次启动时，软件应将此 MTIME 寄存器与所有其他 MTIME 寄存器重新同步



When software updates one, multiple, or all MTIME registers, it must maintain the preceding synchronization requirements (through measuring and then taking into account the differing latencies of performing reads or writes to the different MTIME registers). 
当软件更新一个、多个或所有 MTIME 寄存器时，它必须保持前面的同步要求（需要考虑对不同 MTIME 寄存器执行读取或写入的不同延迟）。



As an example, the below RISC-V 64-bit assembly sequence can be used by software to synchronize a MTIME register with reference to another MTIME register. 
例如，软件可以使用以下 RISC-V 64 位汇编序列来同步 MTIME 寄存器与另一个 MTIME 寄存器的引用。



Listing 1. Synchronizing a MTIME Registers On RISC-V 64-bit Platform 


```Assembly
/*
 * unsigned long aclint_mtime_sync(unsigned long target_mtime_address,
 *                                 unsigned long reference_mtime_address)
 */
        .globl aclint_mtime_sync
aclint_mtime_sync:
        /* Read target MTIME register in T0 register */
        ld        t0, (a0)
        fence     i, i

        /* Read reference MTIME register in T1 register */
        ld        t1, (a1)
        fence     i, i

        /* Read target MTIME register in T2 register */
        ld        t2, (a0)
        fence     i, i

        /*
         * Compute target MTIME adjustment in T3 register
         * T3 = T1 - ((T0 + T2) / 2)
         */
        srli      t0, t0, 1
        srli      t2, t2, 1
        add       t3, t0, t2
        sub       t3, t1, t3

        /* Update target MTIME register */
        ld        t4, (a0)
        add       t4, t4, t3
        sd        t4, (a0)

        /* Return MTIME adjustment value */
        add       a0, t3, zero

        ret
```



***NOTE***: On some RISC-V platforms, the MTIME synchronization sequence (i.e. the `aclint_mtime_sync()` function above) will need to be repeated few times until delta between target MTIME register and reference MTIME register is zero (or very close to zero). 
注意：在一些 RISC-V 平台上，MTIME 同步序列（例如上文中的 `aclint_mtime_sync()` 函数）需要重复执行几次，直到目标 MTIME 寄存器和参考 MTIME 寄存器之间的差值为零（或非常接近零）。



## 3. Machine-level Software Interrupt Device (MSWI) 

The MSWI device provides machine-level IPI functionality for a set of HARTs on a RISC-V platform. It has an IPI register ( **MSIP**) for each HART connected to the MSWI device. 
MSWI 设备为 RISC-V 平台上的一组 HART 提供M-mode IPI 功能。对于连接到 MSWI 设备的每个 HART，它都有一个 IPI 寄存器 (MSIP)。



On a RISC-V platform with multiple MSWI devices, each MSWI device provides machine-level IPI functionality for a different (or disjoint) set of HARTs. A MSWI device assigns a HART index starting from zero to each HART associated with it. The HART index assigned to a HART by the MSWI device may or may not have any relationship with the unique HART identifier ( **hart ID**) that the RISC-V Privileged Architecture assigns to the HART. 
在一个基于 RISC-V 架构的平台上，如果存在多个 MSWI（机器级 IPI）设备，每个 MSWI 设备为一组不同（或不重叠）的 HARTs 提供机器级 IPI 功能。MSWI 设备为与其关联的每个 HART 分配从零开始的 HART 索引。MSWI 设备分配给 HART 的 HART 索引可能与 RISC-V Privileged Architecture 分配给 HART 的唯一 HART 标识符（hart ID）有关系，也可能没有任何关系。



The maximum number of HARTs supported by a single MSWI device is 4095 which is equivalent to the maximum number of MSIP registers. 
单个 MSWI 设备支持的 HART 最大数量为 4095，相当于 MSIP 寄存器的最大数量。



### 3.1. Register Map 

Table 5. ACLINT MSWI Device Register Map 


|Offset |Width |Attr |Name |Description |
|---|---|---|---|---|
|0x0000_0000 |4B |RW |MSIP0 |HART index 0 machine-level IPI register 
HART 索引 0 M-mode IPI 寄存器 |
|0x0000_0004 |4B |RW |MSIP1 |HART index 1 machine-level IPI register 
HART 索引 1 M-mode IPI 寄存器 |
|… |… |… |… |… |
|0x0000_3FFC |4B | |RESERVED |Reserved for future use.  保留以供将来使用。 |
### 3.2. MSIP Registers (Offsets: 0x00000000 - 0x00003FF8) 

Each MSIP register is a 32-bit wide WARL register where the upper 31 bits are wired to zero. The least significant bit is reflected in MSIP of the `mip` CSR. A machine-level software interrupt for a HART is pending or cleared by writing `1` or `0` respectively to the corresponding MSIP register. 
每个 MSIP 寄存器都是一个 32 位宽的 WARL 寄存器，其中高 31 位恒为0。最低有效位反映在 `mip` CSR 的 MSIP 中。通过将 `1` 或 `0` 分别写入相应的 MSIP 寄存器，可以挂起或清除 HART 的M-mode软件中断。



On MSWI device reset, each MSIP register is cleared to zero. 
在 MSWI 设备复位时，每个 MSIP 寄存器都被清零。

## 4. Supervisor-level Software Interrupt Device (SSWI) 

The SSWI device provides supervisor-level IPI functionality for a set of HARTs on a RISC-V platform. It provides a register to set an IPI ( **SETSSIP**) for each HART connected to the SSWI device. 
SSWI 设备为 RISC-V 平台上的一组 HART 提供S-mode  IPI 功能。它提供了一个寄存器来为连接到 SSWI 设备的每个 HART 设置 IPI (SETSSIP)。



On a RISC-V platform with multiple SSWI devices, each SSWI device provides supervisor-level IPI functionality for a different (or disjoint) set of HARTs. A SSWI device assigns a HART index starting from zero to each HART associated with it. The HART index assigned to a HART by the SSWI device may or may not have any relationship with the unique HART identifier ( **hart ID**) that the RISC-V Privileged Architecture assigns to the HART. 
在具有多个 SSWI 设备的 RISC-V 平台上，每个 SSWI 设备为一组不同的（或不相交的）HART 提供S-mode  IPI 功能。 SSWI 设备为与其关联的每个 HART 分配一个从零开始的 HART 索引。 SSWI 设备分配给 HART 的 HART 索引可能与 RISC-V 特权架构分配给 HART 的唯一 HART 标识符（hart ID）有任何关系，也可能没有任何关系。



The maximum number of HARTs supported by a single SSWI device is 4095 which is equivalent to the maximum number of SETSSIP registers. 
单个 SSWI 设备支持的最大 HART 数量为 4095，相当于 SETSSIP 寄存器的最大数量。

### 4.1. Register Map 

Table 6. ACLINT SSWI Device Register Map 

|Offset |Width |Attr |Name |Description |
|---|---|---|---|---|
|0x0000_0000 |4B |RW |SETSSIP0 |HART index 0 set supervisor-level IPI register 
HART 索引 0 设置S-mode  IPI 寄存器 |
|0x0000_0004 |4B |RW |SETSSIP1 |HART index 1 set supervisor-level IPI register HART索引 1组S-mode IPI寄存器 |
|… |… |… |… |… |
|0x0000_3FFC |4B | |RESERVED |Reserved for future use.  保留以供将来使用。 |

### 4.2. SETSSIP Registers (Offsets: 0x00000000 - 0x00003FF8) 

Each SETSSIP register is a 32-bit wide WARL register where the upper 31 bits are wired to zero. The least significant bit of a SETSSIP register always reads `0` . Writing `0` to the least significant bit of a SETSSIP register has no effect whereas writing `1` to the least significant bit sends an edge-sensitive interrupt signal to the corresponding HART causing the HART to set SSIP in the `mip` CSR. Writes to a SETSSIP register are guaranteed to be reflected in SSIP of the corresponding HART but not necessarily immediately. 
每个 SETSSIP 寄存器都是一个 32 位宽的 WARL 寄存器，其中高 31 位恒为零。 SETSSIP 寄存器的最低有效位始终为 `0` 。将 `0` 写入 SETSSIP 寄存器的最低有效位无效，而将 `1` 写入最低有效位会向相应的 HART 发送边沿敏感中断信号，导致 HART 在 `mip` CSR 中设置 SSIP。对 SETSSIP 寄存器的写入保证会反映在相应 HART 的 SSIP 中，但不一定立即反映。



***NOTE***: The RISC-V Privileged Architecture defines SSIP in `mip` and `sip` CSRs as a writeable bit so the M-mode or S-mode software can directly clear SSIP. 
注意：RISC-V 特权架构将 `mip` 和 `sip` CSR 中的 SSIP 定义为可写位，因此 M 模式或 S 模式软件可以直接清除 SSIP。

