---
{"page-title":"Linux 设备驱动之 UIO 机制 - allcloud - 博客园","url":"https://www.cnblogs.com/allcloud/p/7808776.html","date":"2023-12-08 17:02:02","tags":["用户态驱动","OS/Linux"],"dg-publish":true,"permalink":"/BrowserClip/Linux 设备驱动之 UIO 机制 - allcloud - 博客园/","dgPassFrontmatter":true}
---

[原始文档](https://www.cnblogs.com/allcloud/p/7808776.html)

一个设备驱动的主要任务有两个：   
1\. 存取设备的内存   
2\. 处理设备产生的中断

对于第一个任务。UIO 核心实现了mmap()能够处理物理内存(physical memory)，逻辑内存(logical memory)，   
虚拟内存(virtual memory)。UIO驱动的编写是就不须要再考虑这些繁琐的细节。

第二个任务，对于设备中断的应答必须在内核空间进行。所以在内核空间有一小部分代码   
用来应答中断和禁止中断，可是其余的工作所有留给用户空间处理。

假设用户空间要等待一个设备中断，它仅仅须要简单的堵塞在对 /dev/uioX的read()操作上。   
当设备产生中断时，read()操作马上返回。

UIO 也实现了poll()系统调用。你能够使用   
select()来等待中断的发生。select()有一个超时參数能够用来实现有限时间内等待中断。

对设备的控制还能够通过/sys/class/uio下的各个文件的读写来完毕。你注冊的uio设备将会出如今该文件夹下。

  
假如你的uio设备是uio0那么映射的设备内存文件出如今 /sys/class/uio/uio0/maps/mapX。对该文件的读写就是   
对设备内存的读写。

  
例如以下的图描写叙述了uio驱动的内核部分。用户空间部分。和uio 框架以及内核内部函数的关系。

  
![这里写图片描写叙述](https://img-blog.csdn.net/20150716213203197)

二：UIO驱动注册

首先来看一个简单的UIO驱动代码，代码来自网上，非原创，旨在学习

内核部分：
```C
/*

* This is simple demon of uio driver.

* Version 1

*Compile:
*    Save this file name it simple.c
*    #echo "obj -m := simple.o" > Makefile
*    #make -Wall -C /lib/modules/'uname -r'/build M='pwd' modules
*Load the module:
*    #modprobe uio
*    #insmod simple.ko
*/



#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/uio_driver.h>
#include <linux/slab.h>


/*struct uio_info { 
    struct uio_device   *uio_dev; // 在__uio_register_device中初始化
    const char      *name; // 调用__uio_register_device之前必须初始化
    const char      *version; //调用__uio_register_device之前必须初始化
    struct uio_mem      mem[MAX_UIO_MAPS];
    struct uio_port     port[MAX_UIO_PORT_REGIONS];
    long            irq; //分配给uio设备的中断号，调用__uio_register_device之前必须初始化
    unsigned long       irq_flags;// 调用__uio_register_device之前必须初始化
    void            *priv; //
    irqreturn_t (*handler)(int irq, struct uio_info *dev_info); //uio_interrupt中调用，用于中断处理
                                                                // 调用__uio_register_device之前必须初始化
    int (*mmap)(struct uio_info *info, struct vm_area_struct *vma); //在uio_mmap中被调用，
                                                                // 执行设备打开特定操作
    int (*open)(struct uio_info *info, struct inode *inode);//在uio_open中被调用，执行设备打开特定操作
    int (*release)(struct uio_info *info, struct inode *inode);//在uio_device中被调用，执行设备打开特定操作
    int (*irqcontrol)(struct uio_info *info, s32 irq_on);//在uio_write方法中被调用，执行用户驱动的
                                                        //特定操作。
};*/

struct uio_info kpart_info = {  
        .name = "kpart",  
        .version = "0.1",  
        .irq = UIO_IRQ_NONE,  
}; 
static int drv_kpart_probe(struct device *dev);
static int drv_kpart_remove(struct device *dev);
static struct device_driver uio_dummy_driver = {
    .name = "kpart",
    .bus = &platform_bus_type,
    .probe = drv_kpart_probe,
    .remove = drv_kpart_remove,
};

static int drv_kpart_probe(struct device *dev)
{
    printk("drv_kpart_probe(%p)\n",dev);
    kpart_info.mem[0].addr = (unsigned long)kmalloc(1024,GFP_KERNEL);
    
    if(kpart_info.mem[0].addr == 0)
        return -ENOMEM;
    kpart_info.mem[0].memtype = UIO_MEM_LOGICAL;
    kpart_info.mem[0].size = 1024;

    if(uio_register_device(dev,&kpart_info))
        return -ENODEV;
    return 0;
}

static int drv_kpart_remove(struct device *dev)
{
    uio_unregister_device(&kpart_info);
    return 0;
}

static struct platform_device * uio_dummy_device;

static int __init uio_kpart_init(void)
{
    uio_dummy_device = platform_device_register_simple("kpart",-1,NULL,0);
    return driver_register(&uio_dummy_driver);
}

static void __exit uio_kpart_exit(void)
{
    platform_device_unregister(uio_dummy_device);
    driver_unregister(&uio_dummy_driver);
}

module_init(uio_kpart_init);
module_exit(uio_kpart_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("IGB_UIO_TEST");
MODULE_DESCRIPTION("UIO dummy driver");
```

UIO的驱动注册与其他驱动类似，通过调用linux提供的uio API接口进行注册，在注册之前，所做的主要工作是填充uio\_info结构体的信息，主要包括内存大小、类型等信息的填充。填充完毕后调用uio\_register\_device()函数，将uio\_info注册到内核中。注册后，在/sys/class/uio/uioX，其中X是我们注册的第几个uio设备，比如uio0，在该文件夹下的map/map0会有我们刚才填充的一些信息，包括addr、name、size、offset，其中addr保存的是设备的物理地址，size保存的是地址的大小，这些在用户态会将其读出，并mmap至用户态进程空间，这样用户态便可直接操作设备的内存空间。

用户态：
```C
#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>

#define UIO_DEV "/dev/uio0"
#define UIO_ADDR "/sys/class/uio/uio0/maps/map0/addr"
#define UIO_SIZE "/sys/class/uio/uio0/maps/map0/size"

static char uio_addr_buf[16]={0};
static char uio_size_buf[16]={0};

int main(void)
{
    int uio_fd,addr_fd,size_fd;
    int uio_size;
    void *uio_addr, *access_address;
    int n=0;
    uio_fd = open(UIO_DEV,O_RDWR);
    addr_fd = open(UIO_ADDR,O_RDONLY);
    size_fd = open(UIO_SIZE,O_RDONLY);
    if(addr_fd < 0 || size_fd < 0 || uio_fd < 0){
        fprintf(stderr,"mmap:%s\n",strerror(errno));
        exit(-1);
    }

    n=read(addr_fd,uio_addr_buf,sizeof(uio_addr_buf));
    if(n<0){
        fprintf(stderr, "%s\n", strerror(errno));
        exit(-1);
    }
    n=read(size_fd,uio_size_buf,sizeof(uio_size_buf));
    if(n<0){
        fprintf(stderr, "%s\n", strerror(errno));
        exit(-1);
    }
    uio_addr = (void*)strtoul(uio_addr_buf,NULL,0);
    uio_size = (int)strtol(uio_size_buf,NULL,0);

    access_address = mmap(NULL,uio_size,PROT_READ | PROT_WRITE,
                            MAP_SHARED,uio_fd,0);
    if(access_address == (void*)-1){
        fprintf(stderr,"mmap:%s\n",strerror(errno));
        exit(-1);
    }

    printf("The device address %p (lenth %d)\n"
        "can be accessed over\n"
        "logical address %p\n",uio_addr,uio_size,access_address);
/*
    access_address = (void*)(long)mremap(access_address, getpagesize(),uio_size + getpagesize()+ 11111, MAP_SHARED);

    if(access_address == (void*)-1){
        fprintf(stderr,"mremap: %s\n",strerror(errno));
        exit(-1);
    }

    printf(">>>AFTER REMAP:""logical address %p\n",access_address);
*/
    return 0;
}
```



代码很简单，就是讲刚才那几个文件读出来，并且重新mmap出来，最后将其打印出来。由此我们可以简单的看到，想要操作uio设备，只需要重新mmap，而后我们便可操作一般的内存一样操作设备内存，那么dpdk的实现也是类似的，只不过更加复杂一点。

dpdk的uio实现的内核的代码主要在igb\_uio.c中，整理一下主要的代码：

```c
static struct pci_driver igbuio_pci_driver = {
    .name = "igb_uio",
    .id_table = NULL,
    .probe = igbuio_pci_probe,
    .remove = igbuio_pci_remove,
};

module_init(igbuio_pci_init_module);

static int __init
igbuio_pci_init_module(void)
{
    int ret;

    ret = igbuio_config_intr_mode(intr_mode);
    if (ret < 0)
        return ret;

    return pci_register_driver(&igbuio_pci_driver);
}



#if LINUX_VERSION_CODE < KERNEL_VERSION(3,8,0)
static int __devinit
#else
static int
#endif
igbuio_pci_probe(struct pci_dev *dev, const struct pci_device_id *id)
{
    struct rte_uio_pci_dev *udev;

    udev = kzalloc(sizeof(struct rte_uio_pci_dev), GFP_KERNEL);
    if (!udev)
        return -ENOMEM;

    /*
     * enable device: ask low-level code to enable I/O and
     * memory
     */
    if (pci_enable_device(dev)) {
        printk(KERN_ERR "Cannot enable PCI device\n");
        goto fail_free;
    }

    /*
     * reserve device's PCI memory regions for use by this
     * module
     */
    if (pci_request_regions(dev, "igb_uio")) {
        printk(KERN_ERR "Cannot request regions\n");
        goto fail_disable;
    }

    /* enable bus mastering on the device */
    pci_set_master(dev);

    /* remap IO memory */
    if (igbuio_setup_bars(dev, &udev->info))
        goto fail_release_iomem;

    /* set 64-bit DMA mask */
    if (pci_set_dma_mask(dev,  DMA_BIT_MASK(64))) {
        printk(KERN_ERR "Cannot set DMA mask\n");
        goto fail_release_iomem;
    } else if (pci_set_consistent_dma_mask(dev, DMA_BIT_MASK(64))) {
        printk(KERN_ERR "Cannot set consistent DMA mask\n");
        goto fail_release_iomem;
    }

    /* fill uio infos */
    udev->info.name = "Intel IGB UIO";
    udev->info.version = "0.1";
    udev->info.handler = igbuio_pci_irqhandler;
    udev->info.irqcontrol = igbuio_pci_irqcontrol;
#ifdef CONFIG_XEN_DOM0
    /* check if the driver run on Xen Dom0 */
    if (xen_initial_domain())
        udev->info.mmap = igbuio_dom0_pci_mmap;
#endif
    udev->info.priv = udev;
    udev->pdev = dev;
    udev->mode = RTE_INTR_MODE_LEGACY;
    spin_lock_init(&udev->lock);

    /* check if it need to try msix first */
    if (igbuio_intr_mode_preferred == RTE_INTR_MODE_MSIX) {
        int vector;

        for (vector = 0; vector < IGBUIO_NUM_MSI_VECTORS; vector ++)
            udev->msix_entries[vector].entry = vector;

        if (pci_enable_msix(udev->pdev, udev->msix_entries, IGBUIO_NUM_MSI_VECTORS) == 0) {
            udev->mode = RTE_INTR_MODE_MSIX;
        }
        else {
            pci_disable_msix(udev->pdev);
            printk(KERN_INFO "fail to enable pci msix, or not enough msix entries\n");
        }
    }
    switch (udev->mode) {
    case RTE_INTR_MODE_MSIX:
        udev->info.irq_flags = 0;
        udev->info.irq = udev->msix_entries[0].vector;
        break;
    case RTE_INTR_MODE_MSI:
        break;
    case RTE_INTR_MODE_LEGACY:
        udev->info.irq_flags = IRQF_SHARED;
        udev->info.irq = dev->irq;
        break;
    default:
        break;
    }

    pci_set_drvdata(dev, udev);
    igbuio_pci_irqcontrol(&udev->info, 0);

    if (sysfs_create_group(&dev->dev.kobj, &dev_attr_grp))
        goto fail_release_iomem;

    /* register uio driver */
    if (uio_register_device(&dev->dev, &udev->info))
        goto fail_release_iomem;

    printk(KERN_INFO "uio device registered with irq %lx\n", udev->info.irq);

    return 0;

fail_release_iomem:
    sysfs_remove_group(&dev->dev.kobj, &dev_attr_grp);
    igbuio_pci_release_iomem(&udev->info);
    if (udev->mode == RTE_INTR_MODE_MSIX)
        pci_disable_msix(udev->pdev);
    pci_release_regions(dev);
fail_disable:
    pci_disable_device(dev);
fail_free:
    kfree(udev);

    return -ENODEV;
}
```





代码经过整理后，对比上面简单的uio驱动实现，dpdk的uio实现也是首先初始化一个pci\_driver结构体，在igbuio\_pci\_init\_module()函数中直接调用linux提供的pci注册API,pci\_register\_driver(&igbuio\_pci\_driver)，接着便跳到igbuio\_pci\_probe(struct pci\_dev \*dev, const struct pci\_device\_id \*id)函数中，这个函数的功能就是类似于上面例子中内核态代码，rte\_uio\_pci\_dev结构体是dpdk自己封装的，如下：

```c
//在igb_uio自己封装的
struct rte_uio_pci_dev {
    struct uio_info info;
    struct pci_dev *pdev;
    spinlock_t lock; /* spinlock for accessing PCI config space or msix data in multi tasks/isr */
    enum igbuio_intr_mode mode;
    struct msix_entry \
        msix_entries[IGBUIO_NUM_MSI_VECTORS]; /* pointer to the msix vectors to be allocated later */
};
```


可以看到，里面有uio\_info这个结构体，从igbuio\_pci\_probe(struct pci\_dev \*dev, const struct pci\_device\_id \*id)函数代码中可以看到，主要是在填充uio\_info结构体的信息，并且围绕的也是pci设备的物理地址及大小，最后调用linux提供的uio注册接口uio\_register\_device(&dev->dev, &udev->info)，完成整个uio注册。