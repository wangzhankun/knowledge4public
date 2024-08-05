---
{"dg-publish":true,"date":"2024-07-30","time":"13:45","progress":"进行中","tags":["linux/mm","linux/cgroup","云原生/可观测"],"permalink":"/体系结构与操作系统/Linux内核/深入理解Linux page cache/","dgPassFrontmatter":true}
---


# 深入理解Linux page cache


## 声明

本文为本人原创，未经授权严禁转载。如需转载需要在文章最前面注明本文原始链接。

本文参考自 https://biriukov.dev/docs/page-cache/0-linux-page-cache-for-sre/ 进行创作，原始文章为英文且在Arch Linux上进行实验，本文在debian 10上进行实验操作。

## 环境准备
1. 安装 go 环境，python环境，c环境

```sh
sudo apt install gcc git vmtouch
```

2. 安装 page-type 工具，直接从源码构建
```sh
wget https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/snapshot/linux-5.14.tar.gz

tar -xzf linux-5.14.tar.gz
cd linux-5.14/tools/vm
make
sudo make install
```

3. 生成测试文件
```sh
dd if=/dev/random of=/var/tmp/file1.db bs=1M count=128 iflag=fullblock
```
4. 清空page cache
```sh
sync; echo 3 | sudo tee /proc/sys/vm/drop_caches
```

## 理论基础
本质上，页面缓存（page cache）是虚拟文件系统（[VFS](https://en.wikipedia.org/wiki/Virtual_file_system)）的一部分，其主要目的是降低读写操作的 IO 延迟。回写缓存算法是页面缓存的核心。

page cache的最小管理单位是page，无论读写多少数据，所有的io操作都要进行4kB对齐。
![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202407301417274.png)

### 读请求
1. 当用户空间应用程序想要从磁盘读取数据时，它会使用特殊的系统调用如`read()`、`pread()`、`vread()`、`mmap()`、`sendfile()`等来请求内核提供数据。
2. Linux 内核反过来检查页面是否存在于页面缓存中，如果存在，则直接将它们返回给调用者。
3. 如果页面缓存中没有这样的页面，内核必须从磁盘加载它们。内核需要在页面缓存中找到空闲的页面用于存储从磁盘中读取的数据。如果找不到空闲内存（在调用者的 cgroup 或系统中），则需要执行内存回收过程。之后，内核调度一个读取磁盘 IO 操作，将数据读取到相应的页面中，并最终从页面缓存向目标进程返回请求的数据。从这一刻开始，无论来自哪个进程或 cgroup，对文件这部分的任何后续读取请求都将由页面缓存处理，直到这些页面被驱逐，而无需任何磁盘 I/O 操作。
![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202407301427931.png)

### 写请求
1. 当用户空间程序想要向磁盘写入一些数据时，它也会使用一系列系统调用，例如：`write()`，`pwrite()`，`writev()`，`mmap()`等。与读取相比的一大区别是，写入通常更快，因为实际的磁盘 IO 操作不会立即执行。然而，这只有在系统或 cgroup 没有内存压力问题并且有足够的空闲页面的情况下才是正确的（我们稍后会讨论驱逐过程）。因此，内核通常只是更新在 Page Cache 中的页面。这使得写入过程具有异步性质。调用者不知道实际的页面刷新（将内存数据写入磁盘）何时发生，但它确实知道后续的读取将返回最新数据。Page Cache 保护了所有进程和 cgroup 中的数据一致性。包含未刷新数据的此类页面有一个特殊名称：**脏页**。
2. 如果一个进程的数据不是关键的，它可以依赖于内核及其刷新进程，这最终会将数据持久化到物理磁盘上。但如果你开发的是一个数据库管理系统（例如，用于货币交易），你需要写入保证来保护记录不受突然断电的影响。对于这种情况，Linux 提供了 `fsync()`、`fdatasync()` 和 `msync()` 系统调用，它们会阻塞直到文件的所有脏页都被提交到磁盘上。还有 `open()` 函数的标志：`O_SYNC` 和 `O_DSYNC`，你也可以使用这些标志来使所有文件写操作默认情况下都是持久的。后面我会展示一些这个逻辑的示例。

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202407301429818.png)

### 淘汰策略
控制和调整页面缓存的主要方法是 cgroup 子系统。可以将服务器的内存划分为几个较小的缓存（cgroups），从而控制和保护应用程序和服务。此外，cgroup 内存和 IO 控制器提供了大量对软件调优和理解缓存内部结构有用的数据统计信息。

Linux 页面缓存与 Linux 内存管理、cgroup 和虚拟文件系统（VFS）紧密相连。因此，为了理解淘汰机制的工作原理，我们需要从内存回收策略的基本内部结构开始。其核心是**per cgroup pair** of **active and inactive lists**:
- the first pair for anonymous memory (for instance, allocated with `malloc()` or not file backended `mmap()`);
- the second pair for Page Cache file memory (all file operations including `read()`, `write`, file`mmap()` accesses, etc.).
> **per cgroup pair** 是指在 Linux 页面缓存管理中，每个控制组（cgroup）都有一对活跃（active）和非活跃（inactive）的 LRU 列表。这对 LRU 列表用于管理该 cgroup 中的页面缓存，以决定哪些页面应该被保留在缓存中，哪些页面应该被回收以释放内存。具体来说，每个 cgroup 对包括：
   - 第一对 LRU 列表用于管理匿名内存（例如，通过 malloc() 分配或未通过文件后端的 mmap() 分配）。
>   - 第二对 LRU 列表用于管理文件内存（包括所有文件操作，如 read()、write、文件 mmap() 访问等）。
关于LRU列表的管理参见 [[体系结构与操作系统/Linux内核/linux内存源码分析 - 内存回收(lru链表)\|linux内存源码分析 - 内存回收(lru链表)]]


# 实践
## page cache and basic file operations

### 概述
本节将涉及以下内容：
- sync（man 1 sync）：将脏页写入到持久化存储
- - `/proc/sys/vm/drop_caches` ([`man 5 proc`](https://man7.org/linux/man-pages/man5/proc.5.html)) – the kernel `procfs` file to trigger Page Cache clearance;
- [`vmtouch`](https://github.com/hoytech/vmtouch) – a tool for getting Page Cache info about a particular file by its path.

### 读操作
#### read syscall

```py
# dd if=/dev/random of=/var/tmp/file1.db bs=1M count=128 iflag=fullblock
with open("/var/tmp/file1.db", "rb") as f:  
    print(f.read(2))
```

跟踪系统调用：
```sh
sync; echo 3 | sudo tee /proc/sys/vm/drop_caches # 清空page cache
strace -s0 python3 ./read_2_bytes.py
```

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202407311504655.png)

>The `read()` syscall returned 4096 bytes (one page) even though the script asked only for 2 bytes. It’s an example of python optimizations and internal buffered IO. Although this is beyond the scope of this post, but in some cases it is important to keep this in mind.

使用`vmtouch`检查内核缓存了多少数据
```sh
vmtouch /var/tmp/file1.db
```

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202407311516857.png)

从上图可以看出，尽管我们在python代码中仅要求读取2字节，python自动优化读取4KB，但是内核帮我们缓存了16KB。这是因为内核实现了**预读逻辑**，对内核而言顺序读写的开销并不高，因此预读一部分内容进入内存可以加快读取速度。`posix_fadvise()` ([`man 2 posix_fadvise`](https://man7.org/linux/man-pages/man2/posix_fadvise.2.html)) and `readahead()` ([`man 2 readahead`](https://man7.org/linux/man-pages/man2/readahead.2.html)).可以控制预读行为。

下面我们使用`posix_fadvise()`机制告诉内核我们将对文件进行随机读取，关闭预读机制：
首先驱逐页缓存`sync; echo 3 | sudo tee /proc/sys/vm/drop_caches`，然后执行下面的代码

```py
import os
with open("/var/tmp/file1.db", "rb") as f:
	fd = f.fileno()
	os.posix_fadvise(fd, 0, os.fstat(fd).st_size, os.POSIX_FADV_RANDOM)
	print(f.read(2))
```

使用`vmtouch /var/tmp/file1.db`观察结果：
![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202407311524116.png)

此时就只缓存了一个页面

> Note：内核在对数据进行缓存时都是以页为单位的


#### mmap syscall
```py
import mmap

with open("/var/tmp/file1.db", "r") as f:
    with mmap.mmap(f.fileno(), 0, prot=mmap.PROT_READ) as mm:
        print(mm[:2])
        
```

```sh
echo 3 | sudo tee /proc/sys/vm/drop_caches && python3 ./test.py

vmtouch /var/tmp/file1.db 
```

可以看到mmap采取了更为激进的预读策略：

```log
           Files: 1
     Directories: 0
  Resident Pages: 32/32768  128K/128M  0.0977%
         Elapsed: 0.000458 seconds
```

下面关闭预读：
```py
import mmap

with open("/var/tmp/file1.db", "r") as f:
    with mmap.mmap(f.fileno(), 0, prot=mmap.PROT_READ) as mm:
        mm.madvise(mmap.MADV_RANDOM) # python 3.8+
        print(mm[:2])
```

```sh
echo 3 | sudo tee /proc/sys/vm/drop_caches && python3 ./test.py   
```

```
           Files: 1
     Directories: 0
  Resident Pages: 1/32768  4K/128M  0.00305%
         Elapsed: 0.000466 seconds
```

### 写操作

```py
with open("/var/tmp/file1.db", "rb+") as f:
    print(f.write(b"ab"))
```

```sh
sync; echo 3 | sudo tee /proc/sys/vm/drop_caches && python3 ./test.py 
```

```sh
$ vmtouch /var/tmp/file1.db 
           Files: 1
     Directories: 0
  Resident Pages: 1/32768  4K/128M  0.00305%
         Elapsed: 0.000453 seconds
```

内核缓存了4KB
