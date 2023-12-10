---
{"dg-publish":true,"date":"2023-12-10","time":"09:48","progress":"进行中","tags":["驱动","用户态驱动"],"permalink":"/体系结构与操作系统/驱动/O\" — The Linux Kernel documentation --- VFIO/","dgPassFrontmatter":true}
---


[原始链接](https://docs.kernel.org/driver-api/vfio.html)

# VFIO - "Virtual Function I/O" — The Linux Kernel documentation --- VFIO



Many modern systems now provide DMA and interrupt remapping facilities to help ensure I/O devices behave within the boundaries they've been allotted. This includes x86 hardware with AMD-Vi and Intel VT-d, POWER systems with Partitionable Endpoints (PEs) and embedded PowerPC systems such as Freescale PAMU. The VFIO driver is an IOMMU/device agnostic framework for exposing direct device access to userspace, in a secure, IOMMU protected environment. In other words, this allows safe, non-privileged, userspace drivers. 
许多现代系统现在提供 DMA 和中断重新映射功能，以帮助确保 I/O 设备在分配的边界内运行。这包括采用AMD-Vi和Intel VT-d的x86硬件、具有可分区端点（PE）的POWER系统以及飞思卡尔PAMU等嵌入式PowerPC系统。VFIO 驱动程序是一个与 IOMMU/设备无关的框架，用于在受 IOMMU 保护的安全环境中向用户空间公开直接设备访问。换句话说，这允许安全、非特权、用户空间驱动程序。

Why do we want that? Virtual machines often make use of direct device access ("device assignment") when configured for the highest possible I/O performance. From a device and host perspective, this simply turns the VM into a userspace driver, with the benefits of significantly reduced latency, higher bandwidth, and direct use of bare-metal device drivers. 
我们为什么要这样？虚拟机在配置为尽可能高的 I/O 性能时，通常会使用直接设备访问（“设备分配”）。从设备和主机的角度来看，这只会将 VM 转换为用户空间驱动程序，具有显著减少延迟、提高带宽和直接使用裸机设备驱动程序的好处。

Some applications, particularly in the high performance computing field, also benefit from low-overhead, direct device access from userspace. Examples include network adapters (often non-TCP/IP based) and compute accelerators. Prior to VFIO , these drivers had to either go through the full development cycle to become proper upstream driver, be maintained out of tree, or make use of the UIO framework, which has no notion of IOMMU protection, limited interrupt support, and requires root privileges to access things like PCI configuration space. 
一些应用程序，特别是在高性能计算领域，也受益于从用户空间进行低开销的直接设备访问。示例包括网络适配器（通常不基于 TCP/IP）和计算加速器。在 VFIO 之前，这些驱动程序必须经历完整的开发周期才能成为正确的上游驱动程序，在树之外进行维护，或者使用 UIO 框架（该框架没有 IOMMU 保护的概念，有限的中断支持，并且需要 root 权限才能访问 PCI 配置空间等内容）。

The VFIO driver framework intends to unify these, replacing both the KVM PCI specific device assignment code as well as provide a more secure, more featureful userspace driver environment than UIO. 
VFIO 驱动程序框架旨在统一这些，替换 KVM PCI 特定的设备分配代码，并提供比 UIO 更安全、功能更丰富的用户空间驱动程序环境。

## Groups, Devices, and IOMMUs  
组、设备和 IOMMU 

Devices are the main target of any I/O driver. Devices typically create a programming interface made up of I/O access, interrupts, and DMA. Without going into the details of each of these, DMA is by far the most critical aspect for maintaining a secure environment as allowing a device read-write access to system memory imposes the greatest risk to the overall system integrity. 
设备是任何 I/O 驱动程序的主要目标。设备通常创建由 I/O 访问、中断和 DMA 组成的编程接口。在不赘述其中的每一个细节的情况下，DMA 是迄今为止维护安全环境的最关键方面，因为允许设备对系统内存进行读写访问会对整体系统完整性带来最大的风险。

To help mitigate this risk, many modern IOMMUs now incorporate isolation properties into what was, in many cases, an interface only meant for translation (ie. solving the addressing problems of devices with limited address spaces). With this, devices can now be isolated from each other and from arbitrary memory access, thus allowing things like secure direct assignment of devices into virtual machines. 
为了帮助降低这种风险，许多现代 IOMMU 现在将隔离属性合并到在许多情况下仅用于转换的接口中（即解决地址空间有限的设备的寻址问题）。有了这个，设备现在可以彼此隔离，也可以与任意内存访问隔离，从而允许将设备安全地直接分配到虚拟机中。

This isolation is not always at the granularity of a single device though. Even when an IOMMU is capable of this, properties of devices, interconnects, and IOMMU topologies can each reduce this isolation. For instance, an individual device may be part of a larger multi- function enclosure. While the IOMMU may be able to distinguish between devices within the enclosure, the enclosure may not require transactions between devices to reach the IOMMU. Examples of this could be anything from a multi-function PCI device with backdoors between functions to a non-PCI-ACS (Access Control Services) capable bridge allowing redirection without reaching the IOMMU. Topology can also play a factor in terms of hiding devices. A PCIe-to-PCI bridge masks the devices behind it, making transaction appear as if from the bridge itself. Obviously IOMMU design plays a major factor as well. 
但是，这种隔离并不总是在单个设备的粒度上。即使 IOMMU 能够做到这一点，设备、互连和 IOMMU 拓扑的属性也可以分别减少这种隔离。例如，单个设备可能是较大的多功能外壳的一部分。虽然 IOMMU 可能能够区分机柜内的设备，但机柜可能不需要设备之间的事务即可到达 IOMMU。这方面的示例可以是任何东西，从功能之间具有后门的多功能PCI设备到非PCI-ACS（访问控制服务）功能的桥接器，允许在不到达IOMMU的情况下进行重定向。拓扑在隐藏设备方面也可能是一个因素。PCIe 到 PCI 桥接掩盖了其背后的设备，使事务看起来就像来自网桥本身。显然，IOMMU的设计也是一个主要因素。

Therefore, while for the most part an IOMMU may have device level granularity, any system is susceptible to reduced granularity. The IOMMU API therefore supports a notion of IOMMU groups. A group is a set of devices which is isolatable from all other devices in the system. Groups are therefore the unit of ownership used by VFIO . 
因此，虽然在大多数情况下，IOMMU 可能具有设备级粒度，但任何系统都容易受到降低粒度的影响。因此，IOMMU API 支持 IOMMU 组的概念。组是一组可与系统中所有其他设备隔离的设备。因此，组是VFIO使用的所有权单位。

While the group is the minimum granularity that must be used to ensure secure user access, it's not necessarily the preferred granularity. In IOMMUs which make use of page tables, it may be possible to share a set of page tables between different groups, reducing the overhead both to the platform (reduced TLB thrashing, reduced duplicate page tables), and to the user (programming only a single set of translations). For this reason, VFIO makes use of a container class, which may hold one or more groups. A container is created by simply opening the /dev/vfio/vfio character device. 
虽然组是确保安全用户访问所必需的最小粒度，但它不一定是首选粒度。在使用页表的IOMMU中，可以在不同组之间共享一组页表，从而减少平台（减少TLB抖动，减少重复页表）和用户（仅编程一组翻译）的开销。出于这个原因，VFIO 使用容器类，该类可以容纳一个或多个组。只需打开 /dev/vfio/vfio 字符设备即可创建容器。

On its own, the container provides little functionality, with all but a couple version and extension query interfaces locked away. The user needs to add a group into the container for the next level of functionality. To do this, the user first needs to identify the group associated with the desired device. This can be done using the sysfs links described in the example below. By unbinding the device from the host driver and binding it to a VFIO driver, a new VFIO group will appear for the group as /dev/vfio/$GROUP, where $GROUP is the IOMMU group number of which the device is a member. If the IOMMU group contains multiple devices, each will need to be bound to a VFIO driver before operations on the VFIO group are allowed (it's also sufficient to only unbind the device from host drivers if a VFIO driver is unavailable; this will make the group available, but not that particular device). TBD - interface for disabling driver probing/locking a device. 
就其本身而言，容器提供的功能很少，除了几个版本和扩展查询接口外，其他所有接口都被锁定了。用户需要将组添加到容器中才能获得下一级功能。为此，用户首先需要标识与所需设备关联的组。这可以使用以下示例中描述的 sysfs 链接来完成。通过将设备与主机驱动程序解除绑定并将其绑定到 VFIO 驱动程序，该组的新 VFIO 组将显示为 /dev/vfio/$GROUP，其中$GROUP是设备所属的 IOMMU 组号。如果 IOMMU 组包含多个设备，则在允许对 VFIO 组执行操作之前，每个设备都需要绑定到 VFIO 驱动程序（仅当 VFIO 驱动程序不可用时，才将设备与主机驱动程序解除绑定也足够;这将使组可用，但不是该特定设备）。TBD - 用于禁用驱动程序探测/锁定设备的接口。

Once the group is ready, it may be added to the container by opening the VFIO group character device (/dev/vfio/$GROUP) and using the VFIO_GROUP_SET_CONTAINER ioctl, passing the file descriptor of the previously opened container file. If desired and if the IOMMU driver supports sharing the IOMMU context between groups, multiple groups may be set to the same container. If a group fails to set to a container with existing groups, a new empty container will need to be used instead. 
组准备就绪后，可以通过打开 VFIO 组字符设备 （/dev/vfio/$GROUP） 并使用 VFIO_GROUP_SET_CONTAINER ioctl 传递先前打开的容器文件的文件描述符，将其添加到容器中。如果需要，并且 IOMMU 驱动程序支持在组之间共享 IOMMU 上下文，则可以将多个组设置为同一容器。如果组无法设置为具有现有组的容器，则需要改用新的空容器。

With a group (or groups) attached to a container, the remaining ioctls become available, enabling access to the VFIO IOMMU interfaces. Additionally, it now becomes possible to get file descriptors for each device within a group using an ioctl on the VFIO group file descriptor. 
将一个或多个组附加到容器后，剩余的 ioctls 将变为可用，从而可以访问 VFIO IOMMU 接口。此外，现在可以在 VFIO 组文件描述符上使用 ioctl 获取组中每个设备的文件描述符。

The VFIO device API includes ioctls for describing the device, the I/O regions and their read/write/mmap offsets on the device descriptor, as well as mechanisms for describing and registering interrupt notifications. 
VFIO 设备 API 包括用于描述设备的 ioctl、I/O 区域及其在设备描述符上的读/写/mmap 偏移，以及用于描述和注册中断通知的机制。

## VFIO Usage Example   VFIO 使用示例 

Assume user wants to access PCI device 0000:06:0d.0: 
假设用户想要访问 PCI 设备 0000：06：0d.0：

$ readlink /sys/bus/pci/devices/0000:06:0d.0/iommu_group../../../../kernel/iommu_groups/26

This device is therefore in IOMMU group 26. This device is on the pci bus, therefore the user will make use of vfio -pci to manage the group: 
因此，该设备属于IOMMU组26。此设备位于 pci 总线上，因此用户将使用 vfio-pci 来管理组：

Binding this device to the vfio -pci driver creates the VFIO group character devices for this group: 
将此设备绑定到 vfio-pci 驱动程序会为此组创建 VFIO 组字符设备：

$ lspci -n -s 0000:06:0d.006:0d.0 0401: 1102:0002 (rev 08)# echo 0000:06:0d.0 > /sys/bus/pci/devices/0000:06:0d.0/driver/unbind# echo 1102 0002 > /sys/bus/pci/drivers/vfio-pci/new_id

Now we need to look at what other devices are in the group to free it for use by VFIO : 
现在我们需要查看组中还有哪些其他设备可以释放它以供 VFIO 使用：

$ ls -l /sys/bus/pci/devices/0000:06:0d.0/iommu_group/devicestotal 0lrwxrwxrwx. 1 root root 0 Apr 23 16:13 0000:00:1e.0 ->        ../../../../devices/pci0000:00/0000:00:1e.0lrwxrwxrwx. 1 root root 0 Apr 23 16:13 0000:06:0d.0 ->        ../../../../devices/pci0000:00/0000:00:1e.0/0000:06:0d.0lrwxrwxrwx. 1 root root 0 Apr 23 16:13 0000:06:0d.1 ->        ../../../../devices/pci0000:00/0000:00:1e.0/0000:06:0d.1

This device is behind a PCIe-to-PCI bridge 4 , therefore we also need to add device 0000:06:0d.1 to the group following the same procedure as above. Device 0000:00:1e.0 is a bridge that does not currently have a host driver, therefore it's not required to bind this device to the vfio -pci driver (vfio-pci does not currently support PCI bridges). 
此设备位于 PCIe 到 PCI 网桥 4 后面，因此我们还需要按照与上述相同的过程将设备 0000：06：0d.1 添加到组中。设备 0000：00：1e.0 是当前没有主机驱动程序的网桥，因此不需要将此设备绑定到 vfio-pci 驱动程序（vfio-pci 当前不支持 PCI 网桥）。

The final step is to provide the user with access to the group if unprivileged operation is desired (note that /dev/ vfio /vfio provides no capabilities on its own and is therefore expected to be set to mode 0666 by the system): 
最后一步是，如果需要非特权操作，则为用户提供对组的访问权限（请注意，/dev/vfio/vfio 本身不提供任何功能，因此系统应将其设置为模式 0666）：

# chown user:user /dev/vfio/26

The user now has full access to all the devices and the iommu for this group and can access them as follows: 
用户现在可以完全访问此组的所有设备和 immu 并可以按如下方式访问它们：

int container, group, device, i;struct vfio_group_status group_status =                                { .argsz = sizeof(group_status) };struct vfio_iommu_type1_info iommu_info = { .argsz = sizeof(iommu_info) };struct vfio_iommu_type1_dma_map dma_map = { .argsz = sizeof(dma_map) };struct vfio_device_info device_info = { .argsz = sizeof(device_info) };/* Create a new container */container = open("/dev/vfio/vfio", O_RDWR);if (ioctl(container, VFIO_GET_API_VERSION) != VFIO_API_VERSION)        /* Unknown API version */if (!ioctl(container, VFIO_CHECK_EXTENSION, VFIO_TYPE1_IOMMU))        /* Doesn't support the IOMMU driver we want. *//* Open the group */group = open("/dev/vfio/26", O_RDWR);/* Test the group is viable and available */ioctl(group, VFIO_GROUP_GET_STATUS, &group_status);if (!(group_status.flags & VFIO_GROUP_FLAGS_VIABLE))        /* Group is not viable (ie, not all devices bound for vfio) *//* Add the group to the container */ioctl(group, VFIO_GROUP_SET_CONTAINER, &container);/* Enable the IOMMU model we want */ioctl(container, VFIO_SET_IOMMU, VFIO_TYPE1_IOMMU);/* Get addition IOMMU info */ioctl(container, VFIO_IOMMU_GET_INFO, &iommu_info);/* Allocate some space and setup a DMA mapping */dma_map.vaddr = mmap(0, 1024 * 1024, PROT_READ | PROT_WRITE,                     MAP_PRIVATE | MAP_ANONYMOUS, 0, 0);dma_map.size = 1024 * 1024;dma_map.iova = 0; /* 1MB starting at 0x0 from device view */dma_map.flags = VFIO_DMA_MAP_FLAG_READ | VFIO_DMA_MAP_FLAG_WRITE;ioctl(container, VFIO_IOMMU_MAP_DMA, &dma_map);/* Get a file descriptor for the device */device = ioctl(group, VFIO_GROUP_GET_DEVICE_FD, "0000:06:0d.0");/* Test and setup the device */ioctl(device, VFIO_DEVICE_GET_INFO, &device_info);for (i = 0; i < device_info.num_regions; i++) {        struct vfio_region_info reg = { .argsz = sizeof(reg) };        reg.index = i;        ioctl(device, VFIO_DEVICE_GET_REGION_INFO, &reg);        /* Setup mappings... read/write offsets, mmaps         * For PCI devices, config space is a region */}for (i = 0; i < device_info.num_irqs; i++) {        struct vfio_irq_info irq = { .argsz = sizeof(irq) };        irq.index = i;        ioctl(device, VFIO_DEVICE_GET_IRQ_INFO, &irq);        /* Setup IRQs... eventfds, VFIO_DEVICE_SET_IRQS */}/* Gratuitous device reset and go... */ioctl(device, VFIO_DEVICE_RESET);

## IOMMUFD and vfio_iommu_type1  
IOMMUFD 和 vfio_iommu_type1 

IOMMUFD is the new user API to manage I/O page tables from userspace. It intends to be the portal of delivering advanced userspace DMA features (nested translation 5 , PASID 6 , etc.) while also providing a backwards compatibility interface for existing VFIO _TYPE1v2_IOMMU use cases. Eventually the vfio_iommu_type1 driver, as well as the legacy vfio container and group model is intended to be deprecated. 
IOMMUFD 是用于从用户空间管理 I/O 页表的新用户 API。它旨在成为提供高级用户空间DMA功能（嵌套翻译5，PASID 6等）的门户，同时还为现有VFIO_TYPE1v2_IOMMU用例提供向后兼容性接口。最终，vfio_iommu_type1驱动程序以及旧的 vfio 容器和组模型将被弃用。

The IOMMUFD backwards compatibility interface can be enabled two ways. In the first method, the kernel can be configured with CONFIG_IOMMUFD_ VFIO _CONTAINER, in which case the IOMMUFD subsystem transparently provides the entire infrastructure for the VFIO container and IOMMU backend interfaces. The compatibility mode can also be accessed if the VFIO container interface, ie. /dev/vfio/vfio is simply symlink'd to /dev/iommu. Note that at the time of writing, the compatibility mode is not entirely feature complete relative to VFIO_TYPE1v2_IOMMU (ex. DMA mapping MMIO) and does not attempt to provide compatibility to the VFIO_SPAPR_TCE_IOMMU interface. Therefore it is not generally advisable at this time to switch from native VFIO implementations to the IOMMUFD compatibility interfaces. 
可以通过两种方式启用 IOMMUFD 向后兼容性接口。在第一种方法中，内核可以配置CONFIG_IOMMUFD_VFIO_CONTAINER，在这种情况下，IOMMUFD 子系统透明地为 VFIO 容器和 IOMMU 后端接口提供整个基础架构。如果兼容模式可以访问VFIO容器接口，即。/dev/vfio/vfio 只是符号链接到 /dev/iommu。请注意，在撰写本文时，兼容模式相对于VFIO_TYPE1v2_IOMMU并不完全完整（例如 DMA 映射 MMIO），并且不会尝试提供与VFIO_SPAPR_TCE_IOMMU接口的兼容性。因此，目前通常不建议从本机 VFIO 实现切换到 IOMMUFD 兼容性接口。

Long term, VFIO users should migrate to device access through the cdev interface described below, and native access through the IOMMUFD provided interfaces. 
从长远来看，VFIO 用户应通过下面描述的 cdev 接口迁移到设备访问，并通过 IOMMUFD 提供的接口进行本机访问。

## VFIO Device cdev   VFIO 设备 cdev 

Traditionally user acquires a device fd via VFIO _GROUP_GET_DEVICE_FD in a VFIO group. 
传统上，用户通过 VFIO 组中的VFIO_GROUP_GET_DEVICE_FD获取设备 fd。

With CONFIG_ VFIO _DEVICE_CDEV=y the user can now acquire a device fd by directly opening a character device /dev/vfio/devices/vfioX where "X" is the number allocated uniquely by VFIO for registered devices. cdev interface does not support noiommu devices, so user should use the legacy group interface if noiommu is wanted. 
使用 CONFIG_VFIO_DEVICE_CDEV=y，用户现在可以通过直接打开字符设备 /dev/vfio/devices/vfioX 来获取设备 fd，其中“X”是 VFIO 为注册设备唯一分配的数字。cdev 接口不支持 noiommu 设备，因此如果需要 noiommu，用户应使用旧版组接口。

The cdev only works with IOMMUFD. Both VFIO drivers and applications must adapt to the new cdev security model which requires using VFIO_DEVICE_BIND_IOMMUFD to claim DMA ownership before starting to actually use the device. Once BIND succeeds then a VFIO device can be fully accessed by the user. 
cdev 仅适用于 IOMMUFD。VFIO 驱动程序和应用程序都必须适应新的 cdev 安全模型，该模型要求在开始使用设备之前使用 VFIO_DEVICE_BIND_IOMMUFD 来声明 DMA 所有权。一旦 BIND 成功，用户就可以完全访问 VFIO 设备。

VFIO device cdev doesn't rely on VFIO group/container/iommu drivers. Hence those modules can be fully compiled out in an environment where no legacy VFIO application exists. 
VFIO 设备 cdev 不依赖于 VFIO 组/容器/iommu 驱动程序。因此，这些模块可以在不存在遗留 VFIO 应用程序的环境中完全编译出来。

So far SPAPR does not support IOMMUFD yet. So it cannot support device cdev either. 
到目前为止，SPAPR还不支持IOMMUFD。所以它也不能支持设备 cdev。

vfio device cdev access is still bound by IOMMU group semantics, ie. there can be only one DMA owner for the group. Devices belonging to the same group can not be bound to multiple iommufd_ctx or shared between native kernel and vfio bus driver or other driver supporting the driver_managed_dma flag. A violation of this ownership requirement will fail at the VFIO_DEVICE_BIND_IOMMUFD ioctl, which gates full device access. 
VFIO设备CDV访问仍受IOMMU组语义的约束，即。组只能有一个 DMA 所有者。属于同一组的设备不能绑定到多个iommufd_ctx，也不能在本机内核和 vfio 总线驱动程序或支持 driver_managed_dma 标志的其他驱动程序之间共享。违反此所有权要求将在 VFIO_DEVICE_BIND_IOMMUFD IOCTL 失败，该 iotl 将阻止完全设备访问。

## Device cdev Example   设备 cdev 示例 

Assume user wants to access PCI device 0000:6a:01.0: 
假设用户想要访问 PCI 设备 0000：6a：01.0：

$ ls /sys/bus/pci/devices/0000:6a:01.0/vfio-dev/vfio0

This device is therefore represented as vfio 0. The user can verify its existence: 
因此，此设备表示为 vfio0。用户可以验证其是否存在：

$ ls -l /dev/vfio/devices/vfio0crw------- 1 root root 511, 0 Feb 16 01:22 /dev/vfio/devices/vfio0$ cat /sys/bus/pci/devices/0000:6a:01.0/vfio-dev/vfio0/dev511:0$ ls -l /dev/char/511\:0lrwxrwxrwx 1 root root 21 Feb 16 01:22 /dev/char/511:0 -> ../vfio/devices/vfio0

Then provide the user with access to the device if unprivileged operation is desired: 
然后，如果需要非特权操作，则为用户提供对设备的访问权限：

$ chown user:user /dev/vfio/devices/vfio0

Finally the user could get cdev fd by: 
最后，用户可以通过以下方式获得cdev fd：

cdev_fd = open("/dev/vfio/devices/vfio0", O_RDWR);

An opened cdev_fd doesn't give the user any permission of accessing the device except binding the cdev_fd to an iommufd. After that point then the device is fully accessible including attaching it to an IOMMUFD IOAS/HWPT to enable userspace DMA: 
打开的cdev_fd除了将cdev_fd绑定到 iommufd 之外，不会向用户授予访问设备的任何权限。在此之后，设备是完全可访问的，包括将其连接到IOMMUFD IOAS/HWPT以启用用户空间DMA：

struct vfio_device_bind_iommufd bind = {        .argsz = sizeof(bind),        .flags = 0,};struct iommu_ioas_alloc alloc_data  = {        .size = sizeof(alloc_data),        .flags = 0,};struct vfio_device_attach_iommufd_pt attach_data = {        .argsz = sizeof(attach_data),        .flags = 0,};struct iommu_ioas_map map = {        .size = sizeof(map),        .flags = IOMMU_IOAS_MAP_READABLE |                 IOMMU_IOAS_MAP_WRITEABLE |                 IOMMU_IOAS_MAP_FIXED_IOVA,        .__reserved = 0,};iommufd = open("/dev/iommu", O_RDWR);bind.iommufd = iommufd;ioctl(cdev_fd, VFIO_DEVICE_BIND_IOMMUFD, &bind);ioctl(iommufd, IOMMU_IOAS_ALLOC, &alloc_data);attach_data.pt_id = alloc_data.out_ioas_id;ioctl(cdev_fd, VFIO_DEVICE_ATTACH_IOMMUFD_PT, &attach_data);/* Allocate some space and setup a DMA mapping */map.user_va = (int64_t)mmap(0, 1024 * 1024, PROT_READ | PROT_WRITE,                            MAP_PRIVATE | MAP_ANONYMOUS, 0, 0);map.iova = 0; /* 1MB starting at 0x0 from device view */map.length = 1024 * 1024;map.ioas_id = alloc_data.out_ioas_id;;ioctl(iommufd, IOMMU_IOAS_MAP, &map);/* Other device operations as stated in "VFIO Usage Example" */

## VFIO User API   VFIO 用户接口 

Please see include/uapi/linux/ vfio .h for complete API documentation. 
请参阅 include/uapi/linux/vfio.h 获取完整的 API 文档。

## VFIO bus driver API  
VFIO 总线驱动程序 API 

VFIO bus drivers, such as vfio-pci make use of only a few interfaces into VFIO core. When devices are bound and unbound to the driver, Following interfaces are called when devices are bound to and unbound from the driver: 
VFIO 总线驱动程序（如 vfio-pci）仅使用几个接口进入 VFIO 内核。当设备绑定和取消绑定到驱动程序时，当设备绑定到驱动程序和从驱动程序取消绑定时，将调用以下接口：

int vfio_register_group_dev(struct vfio_device *device);int vfio_register_emulated_iommu_dev(struct vfio_device *device);void vfio_unregister_group_dev(struct vfio_device *device);

The driver should embed the vfio _device in its own structure and use vfio_alloc_device() to allocate the structure, and can register @init/@release callbacks to manage any private state wrapping the vfio_device: 
驱动程序应将vfio_device嵌入其自己的结构中，并使用 vfio_alloc_device（） 分配结构，并且可以注册 @init/@release 回调来管理包装vfio_device的任何私有状态：

vfio_alloc_device(dev_struct, member, dev, ops);void vfio_put_device(struct vfio_device *device);

vfio _register_group_dev() indicates to the core to begin tracking the iommu_group of the specified dev and register the dev as owned by a VFIO bus driver. Once vfio_register_group_dev() returns it is possible for userspace to start accessing the driver, thus the driver should ensure it is completely ready before calling it. The driver provides an ops structure for callbacks similar to a file operations structure: 
vfio_register_group_dev（） 指示核心开始跟踪指定开发人员的iommu_group，并将开发人员注册为 VFIO 总线驱动程序拥有。一旦 vfio_register_group_dev（） 返回，用户空间就可以开始访问驱动程序，因此驱动程序应该确保它在调用它之前完全准备就绪。驱动程序为回调提供类似于文件操作结构的操作结构：

struct vfio_device_ops {        char    *name;        int     (*init)(struct vfio_device *vdev);        void    (*release)(struct vfio_device *vdev);        int     (*bind_iommufd)(struct vfio_device *vdev,                                struct iommufd_ctx *ictx, u32 *out_device_id);        void    (*unbind_iommufd)(struct vfio_device *vdev);        int     (*attach_ioas)(struct vfio_device *vdev, u32 *pt_id);        void    (*detach_ioas)(struct vfio_device *vdev);        int     (*open_device)(struct vfio_device *vdev);        void    (*close_device)(struct vfio_device *vdev);        ssize_t (*read)(struct vfio_device *vdev, char __user *buf,                        size_t count, loff_t *ppos);        ssize_t (*write)(struct vfio_device *vdev, const char __user *buf,                 size_t count, loff_t *size);        long    (*ioctl)(struct vfio_device *vdev, unsigned int cmd,                         unsigned long arg);        int     (*mmap)(struct vfio_device *vdev, struct vm_area_struct *vma);        void    (*request)(struct vfio_device *vdev, unsigned int count);        int     (*match)(struct vfio_device *vdev, char *buf);        void    (*dma_unmap)(struct vfio_device *vdev, u64 iova, u64 length);        int     (*device_feature)(struct vfio_device *device, u32 flags,                                  void __user *arg, size_t argsz);};

Each function is passed the vdev that was originally registered in the vfio _register_group_dev() or vfio_register_emulated_iommu_dev() call above. This allows the bus driver to obtain its private data using container_of(). 
每个函数都传递最初在上面的 vfio_register_group_dev（） 或 vfio_register_emulated_iommu_dev（） 调用中注册的 vdev。这允许总线驱动程序使用 container_of（） 获取其私有数据。

- The init/release callbacks are issued when vfio_device is initialized  and released.- The open/close device callbacks are issued when the first  instance of a file descriptor for the device is created (eg.  via VFIO_GROUP_GET_DEVICE_FD) for a user session.- The ioctl callback provides a direct pass through for some VFIO_DEVICE_*  ioctls.- The [un]bind_iommufd callbacks are issued when the device is bound to  and unbound from iommufd.- The [de]attach_ioas callback is issued when the device is attached to  and detached from an IOAS managed by the bound iommufd. However, the  attached IOAS can also be automatically detached when the device is  unbound from iommufd.- The read/write/mmap callbacks implement the device region access defined  by the device's own VFIO_DEVICE_GET_REGION_INFO ioctl.- The request callback is issued when device is going to be unregistered,  such as when trying to unbind the device from the vfio bus driver.- The dma_unmap callback is issued when a range of iovas are unmapped  in the container or IOAS attached by the device. Drivers which make  use of the vfio page pinning interface must implement this callback in  order to unpin pages within the dma_unmap range. Drivers must tolerate  this callback even before calls to open_device().

## PPC64 sPAPR implementation note  
PPC64 sPAPR 实现说明 

This implementation has some specifics: 
此实现具有一些细节：

1. On older systems (POWER7 with P5IOC2/IODA1) only one IOMMU group per container is supported as an IOMMU table is allocated at the boot time, one table per a IOMMU group which is a Partitionable Endpoint (PE) (PE is often a PCI domain but not always). 
在较旧的系统（带有 P5IOC2/IODA1 的 POWER7）上，每个容器仅支持一个 IOMMU 组，因为在引导时分配一个 IOMMU 表，每个 IOMMU 组一个表，这是一个可分区端点 （PE）（PE 通常是 PCI 域，但并非总是如此）。
1. Newer systems (POWER8 with IODA2) have improved hardware design which allows to remove this limitation and have multiple IOMMU groups per a VFIO container. 
较新的系统（带有IODA2的POWER8）具有改进的硬件设计，可以消除此限制，并且每个VFIO容器具有多个IOMMU组。
1. The hardware supports so called DMA windows - the PCI address range within which DMA transfer is allowed, any attempt to access address space out of the window leads to the whole PE isolation. 
硬件支持所谓的 DMA 窗口 - 允许 DMA 传输的 PCI 地址范围，任何访问窗口外地址空间的尝试都会导致整个 PE 隔离。
1. PPC64 guests are paravirtualized but not fully emulated. There is an API to map/unmap pages for DMA, and it normally maps 1..32 pages per call and currently there is no way to reduce the number of calls. In order to make things faster, the map/unmap handling has been implemented in real mode which provides an excellent performance which has limitations such as inability to do locked pages accounting in real time. 
PPC64 客户机是半虚拟化的，但未完全模拟。有一个 API 来映射/取消映射 DMA 的页面，它通常每次调用映射 1..32 个页面，目前没有办法减少调用次数。为了使事情更快，map/unmap处理已在实时模式下实现，这提供了出色的性能，但存在诸如无法实时进行锁定页面记帐之类的限制。
1. According to sPAPR specification, A Partitionable Endpoint (PE) is an I/O subtree that can be treated as a unit for the purposes of partitioning and error recovery. A PE may be a single or multi-function IOA (IO Adapter), a function of a multi-function IOA, or multiple IOAs (possibly including switch and bridge structures above the multiple IOAs). PPC64 guests detect PCI errors and recover from them via EEH RTAS services, which works on the basis of additional ioctl commands. 
根据 sPAPR 规范，可分区端点 （PE） 是一个 I/O 子树，可将其视为一个单元，用于分区和错误恢复。PE 可以是单个或多功能 IOA（IO 适配器）、多功能 IOA 的功能或多个 IOA（可能包括多个 IOA 上方的交换机和桥接结构）。PPC64 客户机检测 PCI 错误并通过 EEH RTAS 服务从中恢复，该服务基于其他 ioctl 命令工作。
1. So 4 additional ioctls have been added: 
因此，添加了 4 个额外的 ioctl：
1. VFIO _IOMMU_SPAPR_TCE_GET_INFO
1. returns the size and the start of the DMA window on the PCI bus. 
返回 PCI 总线上 DMA 窗口的大小和开始时间。
1. VFIO _IOMMU_ENABLE
1. enables the container. The locked pages accounting is done at this point. This lets user first to know what the DMA window is and adjust rlimit before doing any real job. 
启用容器。此时，锁定页面记帐已完成。这使用户可以首先知道DMA窗口是什么，并在执行任何实际工作之前调整rlimit。
1. VFIO _IOMMU_DISABLE
1. disables the container.  禁用容器。
1. VFIO _EEH_PE_OP
1. provides an API for EEH setup, error detection and recovery. 
提供用于 EEH 设置、错误检测和恢复的 API。
1. The code flow from the example above should be slightly changed: 
上面示例中的代码流应该略有更改：
1. struct vfio_eeh_pe_op pe_op = { .argsz = sizeof(pe_op), .flags = 0 };...../* Add the group to the container */ioctl(group, VFIO_GROUP_SET_CONTAINER, &container);/* Enable the IOMMU model we want */ioctl(container, VFIO_SET_IOMMU, VFIO_SPAPR_TCE_IOMMU)/* Get addition sPAPR IOMMU info */vfio_iommu_spapr_tce_info spapr_iommu_info;ioctl(container, VFIO_IOMMU_SPAPR_TCE_GET_INFO, &spapr_iommu_info);if (ioctl(container, VFIO_IOMMU_ENABLE))        /* Cannot enable container, may be low rlimit *//* Allocate some space and setup a DMA mapping */dma_map.vaddr = mmap(0, 1024 * 1024, PROT_READ | PROT_WRITE,                     MAP_PRIVATE | MAP_ANONYMOUS, 0, 0);dma_map.size = 1024 * 1024;dma_map.iova = 0; /* 1MB starting at 0x0 from device view */dma_map.flags = VFIO_DMA_MAP_FLAG_READ | VFIO_DMA_MAP_FLAG_WRITE;/* Check here is .iova/.size are within DMA window from spapr_iommu_info */ioctl(container, VFIO_IOMMU_MAP_DMA, &dma_map);/* Get a file descriptor for the device */device = ioctl(group, VFIO_GROUP_GET_DEVICE_FD, "0000:06:0d.0");..../* Gratuitous device reset and go... */ioctl(device, VFIO_DEVICE_RESET);/* Make sure EEH is supported */ioctl(container, VFIO_CHECK_EXTENSION, VFIO_EEH);/* Enable the EEH functionality on the device */pe_op.op = VFIO_EEH_PE_ENABLE;ioctl(container, VFIO_EEH_PE_OP, &pe_op);/* You're suggested to create additional data struct to represent * PE, and put child devices belonging to same IOMMU group to the * PE instance for later reference. *//* Check the PE's state and make sure it's in functional state */pe_op.op = VFIO_EEH_PE_GET_STATE;ioctl(container, VFIO_EEH_PE_OP, &pe_op);/* Save device state using pci_save_state(). * EEH should be enabled on the specified device. */..../* Inject EEH error, which is expected to be caused by 32-bits * config load. */pe_op.op = VFIO_EEH_PE_INJECT_ERR;pe_op.err.type = EEH_ERR_TYPE_32;pe_op.err.func = EEH_ERR_FUNC_LD_CFG_ADDR;pe_op.err.addr = 0ul;pe_op.err.mask = 0ul;ioctl(container, VFIO_EEH_PE_OP, &pe_op);..../* When 0xFF's returned from reading PCI config space or IO BARs * of the PCI device. Check the PE's state to see if that has been * frozen. */ioctl(container, VFIO_EEH_PE_OP, &pe_op);/* Waiting for pending PCI transactions to be completed and don't * produce any more PCI traffic from/to the affected PE until * recovery is finished. *//* Enable IO for the affected PE and collect logs. Usually, the * standard part of PCI config space, AER registers are dumped * as logs for further analysis. */pe_op.op = VFIO_EEH_PE_UNFREEZE_IO;ioctl(container, VFIO_EEH_PE_OP, &pe_op);/* * Issue PE reset: hot or fundamental reset. Usually, hot reset * is enough. However, the firmware of some PCI adapters would * require fundamental reset. */pe_op.op = VFIO_EEH_PE_RESET_HOT;ioctl(container, VFIO_EEH_PE_OP, &pe_op);pe_op.op = VFIO_EEH_PE_RESET_DEACTIVATE;ioctl(container, VFIO_EEH_PE_OP, &pe_op);/* Configure the PCI bridges for the affected PE */pe_op.op = VFIO_EEH_PE_CONFIGURE;ioctl(container, VFIO_EEH_PE_OP, &pe_op);/* Restored state we saved at initialization time. pci_restore_state() * is good enough as an example. *//* Hopefully, error is recovered successfully. Now, you can resume to * start PCI traffic to/from the affected PE. */....
1. There is v2 of SPAPR TCE IOMMU. It deprecates VFIO _IOMMU_ENABLE/ VFIO_IOMMU_DISABLE and implements 2 new ioctls: VFIO_IOMMU_SPAPR_REGISTER_MEMORY and VFIO_IOMMU_SPAPR_UNREGISTER_MEMORY (which are unsupported in v1 IOMMU). 
有 SPAPR TCE IOMMU 的 v2。它弃用了 VFIO_IOMMU_ENABLE/ VFIO_IOMMU_DISABLE 并实现了 2 个新的 ioctl：VFIO_IOMMU_SPAPR_REGISTER_MEMORY 和 VFIO_IOMMU_SPAPR_UNREGISTER_MEMORY（v1 IOMMU 不支持）。
1. PPC64 paravirtualized guests generate a lot of map/unmap requests, and the handling of those includes pinning/unpinning pages and updating mm::locked_vm counter to make sure we do not exceed the rlimit. The v2 IOMMU splits accounting and pinning into separate operations: 
PPC64 半虚拟化来宾会生成大量映射/取消映射请求，这些请求的处理包括固定/取消固定页面和更新 mm：：locked_vm 计数器，以确保我们不会超过 rlimit。v2 IOMMU 将记帐和固定拆分为单独的操作：
1. This separation helps in optimizing DMA for guests. 
这种分离有助于为客人优化 DMA。
1. sPAPR specification allows guests to have an additional DMA window(s) on a PCI bus with a variable page size. Two ioctls have been added to support this: VFIO _IOMMU_SPAPR_TCE_CREATE and VFIO_IOMMU_SPAPR_TCE_REMOVE. The platform has to support the functionality or error will be returned to the userspace. The existing hardware supports up to 2 DMA windows, one is 2GB long, uses 4K pages and called "default 32bit window"; the other can be as big as entire RAM, use different page size, it is optional - guests create those in run-time if the guest driver supports 64bit DMA. 
sPAPR 规范允许访客在 PCI 总线上具有可变页面大小的附加 DMA 窗口。添加了两个 ioctl 来支持这一点：VFIO_IOMMU_SPAPR_TCE_CREATE 和 VFIO_IOMMU_SPAPR_TCE_REMOVE。平台必须支持该功能，否则错误将返回到用户空间。现有硬件最多支持2个DMA窗口，一个长2GB，使用4K页面，称为“默认32位窗口”;另一个可以与整个 RAM 一样大，使用不同的页面大小，这是可选的 - 如果来宾驱动程序支持 64 位 DMA，则来宾在运行时创建这些页面。
1. VFIO _IOMMU_SPAPR_TCE_CREATE receives a page shift, a DMA window size and a number of TCE table levels (if a TCE table is going to be big enough and the kernel may not be able to allocate enough of physically contiguous memory). It creates a new window in the available slot and returns the bus address where the new window starts. Due to hardware limitation, the user space cannot choose the location of DMA windows. 
VFIO_IOMMU_SPAPR_TCE_CREATE接收页移、DMA 窗口大小和多个 TCE 表级别（如果 TCE 表足够大，并且内核可能无法分配足够的物理连续内存）。它在可用插槽中创建一个新窗口，并返回新窗口启动的总线地址。由于硬件限制，用户空间无法选择 DMA 窗口的位置。
1. VFIO _IOMMU_SPAPR_TCE_REMOVE receives the bus start address of the window and removes it. 
VFIO_IOMMU_SPAPR_TCE_REMOVE接收窗口的总线起始地址并将其删除。

---

1

VFIO was originally an acronym for "Virtual Function I/O" in its initial implementation by Tom Lyon while as Cisco. We've since outgrown the acronym, but it's catchy. 
VFIO最初是“虚拟功能I / O”的首字母缩写，由Tom Lyon在担任思科时最初实施。我们已经超越了首字母缩略词，但它很吸引人。

2

"safe" also depends upon a device being "well behaved". It's possible for multi-function devices to have backdoors between functions and even for single function devices to have alternative access to things like PCI config space through MMIO registers. To guard against the former we can include additional precautions in the IOMMU driver to group multi-function PCI devices together (iommu=group_mf). The latter we can't prevent, but the IOMMU should still provide isolation. For PCI, SR-IOV Virtual Functions are the best indicator of "well behaved", as these are designed for virtualization usage models. 
“安全”还取决于设备是否“表现良好”。多功能设备可以在功能之间有后门，甚至单功能设备也可以通过 MMIO 寄存器替代访问 PCI 配置空间等内容。为了防止前者，我们可以在IOMMU驱动程序中包含额外的预防措施，以将多功能PCI设备组合在一起（iommu=group_mf）。后者我们无法预防，但IOMMU仍应提供隔离。对于PCI，SR-IOV虚拟功能是“行为良好”的最佳指标，因为它们是为虚拟化使用模型设计的。

3

As always there are trade-offs to virtual machine device assignment that are beyond the scope of VFIO . It's expected that future IOMMU technologies will reduce some, but maybe not all, of these trade-offs. 
与往常一样，虚拟机设备分配的权衡超出了 VFIO 的范围。预计未来的IOMMU技术将减少一些，但可能不是全部，这些权衡。

4

In this case the device is below a PCI bridge, so transactions from either function of the device are indistinguishable to the iommu: 
在这种情况下，设备位于 PCI 桥接器下方，因此来自设备任一功能的事务与 iommu 无法区分：

-[0000:00]-+-1e.0-[06]--+-0d.0                        \-0d.100:1e.0 PCI bridge: Intel Corporation 82801 PCI Bridge (rev 90)

5

Nested translation is an IOMMU feature which supports two stage address translations. This improves the address translation efficiency in IOMMU virtualization. 
嵌套转换是 IOMMU 的一项功能，支持两个阶段地址转换。这提高了 IOMMU 虚拟化中的地址转换效率。

6

PASID stands for Process Address Space ID, introduced by PCI Express. It is a prerequisite for Shared Virtual Addressing (SVA) and Scalable I/O Virtualization (Scalable IOV). 
PASID 代表进程地址空间 ID，由 PCI Express 引入。它是共享虚拟寻址 （SVA） 和可扩展 I/O 虚拟化 （可扩展 IOV） 的先决条件。

