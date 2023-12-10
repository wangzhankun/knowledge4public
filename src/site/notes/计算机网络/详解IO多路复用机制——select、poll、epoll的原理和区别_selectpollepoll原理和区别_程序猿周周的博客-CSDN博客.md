---
{"dg-publish":true,"date":"2023-12-10","time":"09:56","progress":"进行中","tags":["OS/Linux","网络"],"permalink":"/计算机网络/详解IO多路复用机制——select、poll、epoll的原理和区别_selectpollepoll原理和区别_程序猿周周的博客-CSDN博客/","dgPassFrontmatter":true}
---

# 详解IO多路复用机制——select、poll、epoll的原理和区别_selectpollepoll原理和区别_程序猿周周的博客-CSDN博客





##   前言

🐶 大家好，我是 [周周 ](https://blog.csdn.net/adminpd)，目前就职于国内短视频小厂BUG攻城狮一枚。
🤺 如果文章对你有帮助， 记得关注、点赞、收藏，一键三连哦 ，你的支持将成为我最大的动力。



###  文章目录

* 前言
*  1 概述
*  2 select
*  3 poll
*  4 epoll
*  5 总结



##    1 概述

select、poll 以及 [epoll ](https://so.csdn.net/so/search?q=epoll&spm=1001.2101.3001.7020)是 Linux 系统的三个系统调用，也是 IO 多路复用模型的具体实现。

由 [前文 五种常见IO模型 ](https://blog.csdn.net/adminpd/article/details/124546529)我们可以知道，IO [多路复用 ](https://so.csdn.net/so/search?q=%E5%A4%9A%E8%B7%AF%E5%A4%8D%E7%94%A8&spm=1001.2101.3001.7020)就是通过一个进程可以监视多个描述符，一旦某个描述符就绪（一般是读就绪或者写就绪），能够通知程序进行相应的读写操作的一种机制。

**IO 多路复用的优点**

与多进程和多线程技术相比，IO 多路复用技术的最大优势是系统开销小，系统不必创建进程或线程，也不必维护这些进程，从而大大减小了系统的开销。

**主流 IO 多路复用机制的基准测试**



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/BnUtbbgd2o34LXxepqbchJv9nzg.jpeg)



##    2 select

```C++
#include <sys/select.h>
#include <sys/time.h>
int select(int maxfdp1, fd_set *readset, fd_set *writeset, fd_set *exceptset,
          const struct timeval *timeout);
// return：表示此时有多少个监控的描述符就绪，若超时则为0，出错为-1。
```

select 函数监视的文件描述符分三类，分别是 writefds、readfds 和 exceptfds。

**select 调用过程**

1）用户进程需要监控某些资源 fds，在调用 select 函数后会阻塞，操作系统会将用户线程加入这些资源的等待队列中。

2）直到有描述副就绪（有数据可读、可写或有 except）或超时（timeout 指定等待时间，如果立即返回设为 null 即可），函数返回。

3）select 函数返回后，中断程序唤起用户线程。用户可以遍历 fds，通过 FD_ISSET 判断具体哪个 fd 收到数据，并做出相应处理。

select 函数优点明显，实现起来简单有效，且几乎所有操作系统都有对应的实现。

**select 的缺点**

1） **每次调用 select 都需要将进程加入到所有监视 fd 的等待队列，每次唤醒都需要从每个队列中移除。**这里涉及了两次遍历，而且每次都要将整个 fd_set 列表传递给内核，有一定的开销。

2）当函数返回时，系统会将就绪描述符写入 fd_set 中，并将其拷贝到用户空间。进程被唤醒后，用户线程并不知道哪些 fd 收到数据，还需要遍历一次。

受 fd_set 的大小限制，32 位系统最多能监听 1024 个 fd，64 位最多监听 2048 个。

##    3 poll

```C++
int poll(struct pollfd* fds, int nfds, int timeout);
/*
struct pollfd{
        int fd;        // 感兴趣fd
        short events;  // 监听事件
        short revents; // 就绪事件
};
*/
// return：表示此时有多少个监控的描述符就绪，若超时则为0，出错为-1。
```

poll 函数与 select 原理相似， **都需要来回拷贝全部监听的文件描述符**，不同的是：

1）poll 函数采用链表的方式替代原来 select 中 fd_set 结构， **因此可监听文件描述符数量不受限**。

2）poll 函数返回后，可以通过 pollfd 结构中的内容进行处理就绪文件描述符，相比 select 效率要高。

3）新增 **水平触发**：也就是通知程序 fd 就绪后，这次没有被处理，那么下次 poll 的时候会再次通知同个 fd 已经就绪。

**poll 缺点**

和 select 函数一样，poll 返回后，需要轮询 pollfd 来获取就绪的描述符。事实上，同时连接的大量客户端在一时刻可能只有很少的处于就绪状态，因此随着监视的描述符数量的增长，其效率也会线性下降。

##    4 epoll

epoll 在 2.6 内核中提出，是之前的 select 和 poll 的增强版。

```C++
int epoll_create(int size)；//创建一个epoll的句柄，size用来告诉内核这个监听的数目一共有多大
int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event)；
int epoll_wait(int epfd, struct epoll_event * events, int maxevents, int timeout);
```

epoll 使用一个文件描述符管理多个描述符，将用户进程监控的文件描述符的事件存放到内核的一个事件表中，这样在用户空间和内核空间只需拷贝一次。

###    4.1 函数定义

* **epoll_create**

创建一个 epoll 的句柄，参数 size 并非限制了 epoll 所能监听的描述符最大个数，只是对内核初始分配内部数据结构的一个建议。

当 epoll 句柄创建后，它就会占用一个 fd 值，在 linux 中查看/proc/进程id/fd/，能够看到这个 fd，所以 epoll 使用完后，必须调用 close() 关闭，否则可能导致 fd 被耗尽。

* **epoll_ctl**

事件注册函数，将需要监听的事件和需要监听的 fd 交给 epoll 对象。

OP 用三个宏来表示：添加（EPOLL_CTL_ADD）、删除（EPOLL_CTL_DEL）、修改（EPOLL_CTL_MOD）。分别表示添加、删除和修改 fd 的监听事件。

```C++
struct epoll_event {
  __uint32_t events;  /* Epoll events */
  epoll_data_t data;  /* User data variable */
};

//events可以是以下几个宏的集合：
EPOLLIN ：表示对应的文件描述符可以读（包括对端SOCKET正常关闭）；
EPOLLOUT：表示对应的文件描述符可以写；
EPOLLPRI：表示对应的文件描述符有紧急的数据可读（这里应该表示有带外数据到来）；
EPOLLERR：表示对应的文件描述符发生错误；
EPOLLHUP：表示对应的文件描述符被挂断；
EPOLLET： 将EPOLL设为边缘触发(Edge Triggered)模式，这是相对于水平触发(Level Triggered)来说的。
EPOLLONESHOT：只监听一次事件，当监听完这次事件之后，如果还需要继续监听这个socket的话，需要再次把这个socket加入到EPOLL队列里
```

通过 epoll_ctl 函数添加进来的事件都会被放在红黑树的某个节点内，所以，重复添加是没有用的。

当把事件添加进来的时候时候会完成关键的一步，那就是该事件都会与相应的设备驱动程序建立回调关系，当相应的事件发生后，就会调用这个回调函数，该回调函数在内核中被称为 `ep_poll_callback` ，这个回调函数其实就所把这个事件添加到 rdllist 这个双向链表中。一旦有事件发生，epoll 就会将该事件添加到双向链表中。那么当我们调用 epoll_wait 时，epoll_wait 只需要检查 rdlist 双向链表中是否有存在注册的事件，效率非常可观。这里也需要将发生了的事件复制到用户态内存中即可。



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/FaLUbrYMYoVNh6x34OYcRPPindd.jpeg)



上图我们可以看出， **所有 FD 集合采用红黑树存储，就绪 FD 集合使用链表存储**。这是因为就绪 FD 都需要处理，业务优先级需求，最好的选择便是线性数据结构。

* **epoll_wait**

等待 epfd 上的 io 事件，最多返回 maxevents 个事件。参数timeout是超时时间（毫秒，0会立即返回，-1将不确定，也有说法说是永久阻塞）。

1）epoll_wait调用ep_poll，当rdlist为空（无就绪fd）时挂起当前进程，直到rdlist不空时进程才被唤醒。

2）文件fd状态改变（buffer由不可读变为可读或由不可写变为可写），导致相应fd上的回调函数ep_poll_callback()被调用。

3）ep_poll_callback将相应fd对应epitem加入rdlist，导致rdlist不空，进程被唤醒，epoll_wait得以继续执行。

4）ep_events_transfer函数将rdlist中的epitem拷贝到txlist中，并将rdlist清空。

5）ep_send_events函数（很关键），它扫描txlist中的每个epitem，调用其关联fd对用的poll方法。此时对poll的调用仅仅是取得fd上较新的events（防止之前events被更新），之后将取得的events和相应的fd发送到用户空间（封装在struct epoll_event，从epoll_wait返回）。

###    4.2 工作模式

**1）LT模式**

LT（level triggered）模式：也是默认模式，即当 epoll_wait 检测到描述符事件发生并将此事件通知应用程序， **应用程序可以不立即处理该事件**，并且下次调用 epoll_wait 时，会再次响应应用程序并通知此事件。

**2）ET模式**

ET（edge-triggered）模式：当 epoll_wait 检测到描述符事件发生并将此事件通知应用程序， **应用程序必须立即处理该事件**。如果不处理，下次调用epoll_wait时，不会再次响应应用程序并通知此事件。

ET 是一种高速工作方式，很大程度上减少了 epoll 事件被重复触发的次数。epoll 工作在 ET 模式的时候，必须使用非阻塞套接口，以避免由于一个文件句柄的阻塞读/阻塞写操作把处理多个文件描述符的任务饿死。

###    4.3 为何高效

1） epoll 精巧的使用了 3 个方法来实现 select 方法要做的事，分清了频繁调用和不频繁调用的操作。

epoll_ctrl 是不太频繁调用的，而 epoll_wait 是非常频繁调用的。而 epoll_wait 却几乎没有入参，这比 select 的效率高出一大截，而且，它也不会随着并发连接的增加使得入参越发多起来，导致内核执行效率下降。

2） mmap 的引入， **将用户空间的一块地址和内核空间的一块地址同时映射到相同的一块物理内存地址**（不管是用户空间还是内核空间都是虚拟地址，最终要通过地址映射映射到物理地址），使得这块物理内存对内核和对用户均可见，减少用户态和内核态之间的数据交换。

3）红黑树将存储 epoll 所监听的 FD。高效的数据结构，本身插入和删除性能比较好，时间复杂度O(logN)。

##    5 总结

三种函数在的 Linux 内核里有都能够支持，其中 epoll 是 Linux 所特有，而 select 则应该是 POSIX 所规定，一般操作系统均有实现。

###    5.1 三种机制的区别



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/UooybaWuOoWM7xxraEecv6C3nCd.jpeg)



*摘录自《linux高性能服务器编程》*

###    5.2 epoll 优点

1）没有最大并发连接的限制，能打开的 FD 的上限远大于 1024。

2）效率提升，不是轮询的方式，不会随着 FD 数目的增加效率下降。

3）内存拷贝，利用 mmap() 文件映射内存加速与内核空间的消息传递，即 epoll 使用 mmap 减少复制开销。

4）新增 ET 模式。



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/DNNBbZNqBofaiQxtDQicnojXnfb.gif)





   

显示推荐内容

