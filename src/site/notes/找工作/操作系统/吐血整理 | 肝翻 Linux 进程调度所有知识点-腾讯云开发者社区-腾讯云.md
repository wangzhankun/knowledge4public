---
{"dg-publish":true,"date":"2023-12-09","time":"21:02","progress":"进行中","tags":["OS"],"permalink":"/找工作/操作系统/吐血整理 | 肝翻 Linux 进程调度所有知识点-腾讯云开发者社区-腾讯云/","dgPassFrontmatter":true}
---

# 吐血整理 | 肝翻 Linux 进程调度所有知识点-腾讯云开发者社区-腾讯云

前面我们重点分析了如何通过 fork, vfork, pthread_create 去创建一个进程或者线程，以及后面说了它们共同调用 do_fork 的实现。现在已经知道一个进程是如何创建的，但是进程何时被执行，需要调度器来选择。所以这一节我们介绍下进程调度和进程切换的详情。

## **进程的分类**



在 CPU 的角度看进程行为的话，可以分为两类：

* CPU 消耗型：此类进程就是一直占用 CPU 计算，CPU 利用率很高
* IO 消耗型：此类进程会涉及到 IO，需要和用户交互，比如键盘输入，占用 CPU 不是很高，只需要 CPU 的一部分计算，大多数时间是在等待 IO

CPU 消耗型进程需要高的吞吐率，IO 消耗型进程需要强的响应性，这两点都是调度器需要考虑的。

为了更快响应 IO 消耗型进程，内核提供了一个抢占(preempt)机制，使优先级更高的进程，去抢占优先级低的进程运行。内核用以下宏来选择内核是否打开抢占机制：

* CONFIG_PREEMPT_NONE: 不打开抢占，主要是面向 [服务器 ](https://cloud.tencent.com/act/pro/promotion-cvm?from_column=20065&from=20065)。此配置下，CPU 在计算时，当输入键盘之后，因为没有抢占，可能需要一段时间等待键盘输入的进程才会被 CPU 调度。
* CONFIG_PREEMPT : 打开抢占，一般多用于手机设备。此配置下，虽然会影响吞吐率，但可以及时响应用户的输入操作。

## **调度相关的数据结构**

先来看几个相关的数据结构：

### **task_struct**

我们先把 task_struct 中和调度相关的结构拎出来：

```JavaScript
struct task_struct {
 ......
 const struct sched_class *sched_class;
 struct sched_entity  se;
 struct sched_rt_entity  rt;
 ......
 struct sched_dl_entity  dl;
 ......
 unsigned int   policy;
 ......
}
```

* struct sched_class：对调度器进行抽象，一共分为5类。

1. Stop调度器：优先级最高的调度类，可以抢占其他所有进程，不能被其他进程抢占；
1. Deadline调度器：使用红黑树，把进程按照绝对截止期限进行排序，选择最小进程进行调度运行；
1. RT调度器：为每个优先级维护一个队列；
1. CFS调度器：采用完全公平调度算法，引入虚拟运行时间概念；
1. IDLE-Task调度器：每个CPU都会有一个idle线程，当没有其他进程可以调度时，调度运行idle线程；

* unsigned int policy：进程的调度策略有6种，用户可以调用调度器里的不同调度策略。

1. SCHED_DEADLINE：使task选择Deadline调度器来调度运行
1. SCHED_RR：时间片轮转，进程用完时间片后加入优先级对应运行队列的尾部，把CPU让给同优先级的其他进程；
1. SCHED_FIFO：先进先出调度没有时间片，没有更高优先级的情况下，只能等待主动让出CPU；
1. SCHED_NORMAL：使task选择CFS调度器来调度运行；
1. SCHED_BATCH：批量处理，使task选择CFS调度器来调度运行；
1. SCHED_IDLE：使task以最低优先级选择CFS调度器来调度运行；



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/Calbb5x7Zol3YqxaFaIcFmJRnse.png)



* struct sched_entity se：采用CFS算法调度的普通非实时进程的调度实体。
* struct sched_rt_entity        rt：采用Roound-Robin或者FIFO算法调度的实时调度实体。
* struct sched_dl_entity        dl：采用EDF算法调度的实时调度实体。

分配给 CPU 的 task，作为调度实体加入到运行队列中。

### **runqueue 运行队列**

runqueue 运行队列是本 CPU 上所有可运行进程的队列集合。每个 CPU 都有一个运行队列，每个运行队列中有三个调度队列，task 作为调度实体加入到各自的调度队列中。

```JavaScript
struct rq {
 ......
 struct cfs_rq cfs;
 struct rt_rq rt;
 struct dl_rq dl;
 ......
}
```

三个调度队列：

* struct cfs_rq cfs：CFS调度队列
* struct rt_rq rt：RT调度队列
* struct dl_rq dl：DL调度队列



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/BTTXbXOkho8Z1yx2taqc86HqnRb.png)



* cfs_rq：跟踪就绪队列信息以及管理就绪态调度实体，并维护一棵按照虚拟时间排序的红黑树。tasks_timeline->rb_root是红黑树的根，tasks_timeline->rb_leftmost指向红黑树中最左边的调度实体，即虚拟时间最小的调度实体。

```JavaScript
struct cfs_rq {
  ...
  struct rb_root_cached tasks_timeline
  ...
};
```

* sched_entity：可被内核调度的实体。每个就绪态的调度实体sched_entity包含插入红黑树中使用的节点rb_node，同时vruntime成员记录已经运行的虚拟时间。

```JavaScript
struct sched_entity {
  ...
  struct rb_node    run_node;      
  ...
  u64          vruntime;              
  ...
};
```

这些数据结构的关系如下图所示：



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/DI1mbIT5qom3eBxgEdtc2BT6n06.png)



## **调度时刻**

调度的本质就是选择下一个进程，然后切换。在执行调度之前需要设置调度标记 TIF_NEED_RESCHED，然后在调度的时候会判断当前进程有没有被设置 TIF_NEED_RESCHED，如果设置则调用函数 schedule 来进行调度。

### **1. 设置调度标记**

为 CPU 上正在运行的进程 thread_info 结构体里的 flags 成员设置 TIF_NEED_RESCHED。

那么，什么时候设置TIF_NEED_RESCHED呢 ？

1. scheduler_tick 时钟中断



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/QkINbEH5joBqwyxSxq6cQoJJn5d.png)



2. wake_up_process 唤醒进程的时候



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/Bk4PbO6tYoLyvZx3Qwucbks5nDd.png)



3. do_fork 创建新进程的时候



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/BX9Kbr6oXo1LtCxMPQ0cIX6anzd.png)



4. set_user_nice 修改进程nice值的时候



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/ZaHObMD81ogh82xrwmlcCZntn2c.png)



5. smp_send_reschedule [负载均衡 ](https://cloud.tencent.com/product/clb?from_column=20065&from=20065)的时候

### **2. 执行调度**

Kernel 判断当前进程标记是否为 TIF_NEED_RESCHED，是的话调用 schedule 函数，执行调度，切换上下文，这也是上面抢占(preempt)机制的本质。那么在哪些情况下会执行 schedule 呢？

1. 用户态抢占

ret_to_user 是异常触发，系统调用，中断处理完成后都会调用的函数。



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/OiTKbIPnqoXLqQxUqUScpSFtnAf.png)



2. 内核态抢占



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/MEYWbH6R6o13CWxIM1JcSfA8nBh.png)



可以看出无论是用户态抢占，还是内核态抢占，最终都会调用 schedule 函数来执行真正的调度：



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/V0NfbJsxeohljHxnK85cnYYon8f.png)



还记得调度的本质吗？调度的本质就是选择下一个进程，然后切换。如上图所示，用函数 pick_next_task 选择下一个进程，其本质就是调度算法的实现；用函数 context_switch 完成进程的切换，即进程上下文的切换。下面我们分别看下这两个核心功能。

## **调度算法**

| | |
|---|---|
|O(n) 调度器 |linux0.11 - 2.4 |
|O(1) 调度器 |linux2.6 |
|CFS调度器 |linux2.6至今 |
### **O(n)**

O(n) 调度器是在内核2.4以及更早期版本采用的算法，O(n) 代表的是寻找一个合适的任务的时间复杂度。调度器定义了一个 runqueue 的运行队列，将进程的状态变为 Running 的都会添加到此运行队列中，但是不管是实时进程，还是普通进程都会添加到这个运行队列中。当需要从运行队列中选择一个合适的任务时，就需要从队列的头遍历到尾部，这个时间复杂度是O(n)，运行队列中的任务数目越大，调度器的效率就越低。



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/L2gQbJUCLoW8mTxMlrLcv4wRneT.png)



所以 O(n) 调度器有如下缺陷：

* 时间复杂度是 O(n)，运行队列中的任务数目越大，调度器的效率就越低。
* 实时进程不能及时调度，因为实时进程和普通进程在一个列表中，每次查实时进程时，都需要全部扫描整个列表，所以实时进程不是很“实时”。
* SMP 系统不好，因为只有一个 runqueue，选择下一个任务时，需要对这个 runqueue 队列进行加锁操作，当任务较多的时候，则在临界区的时间就比较长，导致其余的 CPU 自旋浪费。
* CPU空转的现象存在，因为系统中只有一个runqueue，当运行队列中的任务少于 CPU 的个数时，其余的 CPU 则是 idle 状态。

### **O(1)**

内核2.6采用了O(1) 调度器，让每个 CPU 维护一个自己的 runqueue，从而减少了锁的竞争。每一个runqueue 运行队列维护两个链表，一个是 active 链表，表示运行的进程都挂载 active 链表中；一个是 expired 链表，表示所有时间片用完的进程都挂载 expired 链表中。当 acitve 中无进程可运行时，说明系统中所有进程的时间片都已经耗光，这时候则只需要调整 active 和 expired 的指针即可。每个优先级数组包含140个优先级队列，也就是每个优先级对应一个队列，其中前100个对应实时进程，后40个对应普通进程。如下图所示：



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/Ex70busXQoEARHxXd6qc5bxVnDT.png)



总的来说 O(1) 调度器的出现是为了解决 O(n) 调度器不能解决的问题，但 O(1) 调度器有个问题，一个高优先级多线程的应用会比低优先级单线程的应用获得更多的资源，这就会导致一个调度周期内，低优先级的应用可能一直无法响应，直到高优先级应用结束。CFS调度器就是站在一视同仁的角度解决了这个问题，保证在一个调度周期内每个任务都有执行的机会，执行时间的长短，取决于任务的权重。下面详细看下CFS调度器是如何动态调整任务的运行时间，达到公平调度的。

## **CFS 调度器**

CFS是 Completely Fair Scheduler 简称，即完全公平调度器。CFS 调度器和以往的调度器不同之处在于没有固定时间片的概念，而是公平分配 CPU 使用的时间。比如：2个优先级相同的任务在一个 CPU 上运行，那么每个任务都将会分配一半的 CPU 运行时间，这就是要实现的公平。

但现实中，必然是有的任务优先级高，有的任务优先级低。CFS 调度器引入权重 weight 的概念，用 weight 代表任务的优先级，各个任务按照 weight 的比例分配 CPU 的时间。比如：2个任务A和B，A的权重是1024，B的权重是2048，则A占 1024/(1024+2048) = 33.3% 的 CPU 时间，B占 2048/(1024+2048)=66.7% 的 CPU 时间。

在引入权重之后，分配给进程的时间计算公式如下：

**实际运行时间 = 调度周期 * 进程权重 / 所有进程权重之和**

CFS 调度器用nice值表示优先级，取值范围是[-20, 19]，nice和权重是一一对应的关系。数值越小代表优先级越大，同时也意味着权重值越大，nice值和权重之间的转换关系：

```JavaScript
const int sched_prio_to_weight[40] = {
 /* -20 */     88761,     71755,     56483,     46273,     36291,
 /* -15 */     29154,     23254,     18705,     14949,     11916,
 /* -10 */      9548,      7620,      6100,      4904,      3906,
 /*  -5 */      3121,      2501,      1991,      1586,      1277,
 /*   0 */      1024,       820,       655,       526,       423,
 /*   5 */       335,       272,       215,       172,       137,
 /*  10 */       110,        87,        70,        56,        45,
 /*  15 */        36,        29,        23,        18,        15,
}; 
```

数组值计算公式是：weight = 1024 / 1.25nice。

### **调度周期**

如果一个 CPU 上有 N 个优先级相同的进程，那么每个进程会得到 1/N 的执行机会，每个进程执行一段时间后，就被调出，换下一个进程执行。如果这个 N 的数量太大，导致每个进程执行的时间很短，就要调度出去，那么系统的资源就消耗在进程上下文切换上去了。

所以对于此问题在 CFS 中则引入了调度周期，使进程至少保证执行0.75ms。调度周期的计算通过如下代码：

```JavaScript
static u64 __sched_period(unsigned long nr_running)
{
 if (unlikely(nr_running > sched_nr_latency))
  return nr_running * sysctl_sched_min_granularity;
 else
  return sysctl_sched_latency;
}
 
static unsigned int sched_nr_latency = 8;
unsigned int sysctl_sched_latency   = 6000000ULL;
unsigned int sysctl_sched_min_granularity   = 750000ULL;
```

当进程数目小于8时，则调度周期等于6ms。当进程数目大于8时，则调度周期等于进程的数目乘以0.75ms。

### **虚拟运行时间**

根据上面进程实际运行时间的公式，可以看出，权重不同的2个进程的实际执行时间是不相等的，但是 CFS 想保证每个进程运行时间相等，因此 CFS 引入了虚拟时间的概念。虚拟时间(vriture_runtime)和实际时间(wall_time)转换公式如下：

**vriture_runtime = (wall_time * NICE0_TO_weight) / weight**

其中，NICE0_TO_weight 代表的是 nice 值等于0对应的权重，即1024，weight 是该任务对应的权重。

权重越大的进程获得的虚拟运行时间越小，那么它将被调度器所调度的机会就越大，所以， **CFS 每次调度原则是：总是选择 vriture_runtime 最小的任务来调度**。

为了能够快速找到虚拟运行时间最小的进程，Linux 内核使用红黑树来保存可运行的进程。CFS跟踪调度实体sched_entity的虚拟运行时间vruntime，将sched_entity通过enqueue_entity()和dequeue_entity()来进行红黑树的出队入队，vruntime少的调度实体sched_entity排列到红黑树的左边。



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/Xro0bCe2mo1msFxEwd2cWDK3nJe.png)



如上图所示，红黑树的左节点比父节点小，而右节点比父节点大。所以查找最小节点时，只需要获取红黑树的最左节点即可。

相关步骤如下：

1. 每个sched_latency周期内，根据各个任务的权重值，可以计算出运行时间runtime；
1. 运行时间runtime可以转换成虚拟运行时间vruntime；
1. 根据虚拟运行时间的大小，插入到CFS红黑树中，虚拟运行时间少的调度实体放置到左边；



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/U6h5bcMVEolrpUxz3ric2uc0nLc.png)



1. 在 **下一次任务调度**的时候，选择虚拟运行时间少的调度实体来运行。pick_next_task 函数就是从从就绪队列中选择最适合运行的调度实体，即虚拟时间最小的调度实体，下面我们看下 CFS 调度器如何通过 pick_next_task 的回调函数 pick_next_task_fair 来选择下一个进程的。

## **选择下一个进程**



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/GkRybksj2oa9iHxbByFcXH62nVf.png)



pick_next_task_fair 会判断上一个 task 的调度器是否是 CFS，这里我们默认都是 CFS 调度：



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/QvzSb4sa3oHbwaxKw9Pcwpemnbh.png)



### **update_curr**

update_curr 函数用来更新当前进程的运行时间信息:

```JavaScript
static void update_curr(struct cfs_rq *cfs_rq)
{
 struct sched_entity *curr = cfs_rq->curr;
 u64 now = rq_clock_task(rq_of(cfs_rq));
 u64 delta_exec;
 
 if (unlikely(!curr))
  return;
 
 delta_exec = now - curr->exec_start;                  ------(1)
 if (unlikely((s64)delta_exec <= 0))
  return;
 
 curr->exec_start = now;                               ------(2)
 
 schedstat_set(curr->statistics.exec_max,
        max(delta_exec, curr->statistics.exec_max));
 
 curr->sum_exec_runtime += delta_exec;                 ------(3)
 schedstat_add(cfs_rq->exec_clock, delta_exec);
 
 curr->vruntime += calc_delta_fair(delta_exec, curr);  ------(4)
 update_min_vruntime(cfs_rq);                          ------(5)
 
 
 account_cfs_rq_runtime(cfs_rq, delta_exec);
}
```

1. delta_exec = now - curr->exec_start; 计算出当前CFS运行队列的进程，距离上次更新虚拟时间的差值
1. curr->exec_start = now; 更新exec_start的值
1. curr->sum_exec_runtime += delta_exec; 更新当前进程总共执行的时间
1. 通过 calc_delta_fair 计算当前进程虚拟时间
1. 通过 update_min_vruntime 函数来更新CFS运行队列中最小的 vruntime 的值

### **pick_next_entity**

pick_next_entity 函数会从就绪队列中选择最适合运行的调度实体（虚拟时间最小的调度实体），即从 CFS 红黑树最左边节点获取一个调度实体。

```JavaScript
static struct sched_entity *
pick_next_entity(struct cfs_rq *cfs_rq, struct sched_entity *curr)
{
 struct sched_entity *left = __pick_first_entity(cfs_rq);    ------(1)
 struct sched_entity *se;

 /*
  * If curr is set we have to see if its left of the leftmost entity
  * still in the tree, provided there was anything in the tree at all.
  */
 if (!left || (curr && entity_before(curr, left)))
  left = curr;

 se = left; /* ideally we run the leftmost entity */

 /*
  * Avoid running the skip buddy, if running something else can
  * be done without getting too unfair.
  */
 if (cfs_rq->skip == se) {
  struct sched_entity *second;

  if (se == curr) {
   second = __pick_first_entity(cfs_rq);                   ------(2)
  } else {
   second = __pick_next_entity(se);                        ------(3)
   if (!second || (curr && entity_before(curr, second)))
    second = curr;
  }

  if (second && wakeup_preempt_entity(second, left) < 1)
   se = second;
 }

 /*
  * Prefer last buddy, try to return the CPU to a preempted task.
  */
 if (cfs_rq->last && wakeup_preempt_entity(cfs_rq->last, left) < 1)
  se = cfs_rq->last;

 /*
  * Someone really wants this to run. If it's not unfair, run it.
  */
 if (cfs_rq->next && wakeup_preempt_entity(cfs_rq->next, left) < 1)
  se = cfs_rq->next;

 clear_buddies(cfs_rq, se);

 return se;
}
```

1. 从树中挑选出最左边的节点
1. 选择最左的那个调度实体 left
1. 摘取红黑树上第二左的进程节点

### **put_prev_entity**

put_prev_entity 会调用 __enqueue_entity 将prev进程(即current进程)加入到 CFS 队列 rq 上的红黑树，然后将 cfs_rq->curr 设置为空。

```JavaScript
static void __enqueue_entity(struct cfs_rq *cfs_rq, struct sched_entity *se)
{
 struct rb_node **link = &cfs_rq->tasks_timeline.rb_root.rb_node; //红黑树根节点
 struct rb_node *parent = NULL;
 struct sched_entity *entry;
 bool leftmost = true;

 /*
  * Find the right place in the rbtree:
  */
 while (*link) {                                ------(1)
  parent = *link;
  entry = rb_entry(parent, struct sched_entity, run_node);
  /*
   * We dont care about collisions. Nodes with
   * the same key stay together.
   */
  if (entity_before(se, entry)) {              ------(2)
   link = &parent->rb_left;
  } else {
   link = &parent->rb_right;
   leftmost = false;
  }
 }
  
 rb_link_node(&se->run_node, parent, link);     ------(3)
 rb_insert_color_cached(&se->run_node,          ------(4)
          &cfs_rq->tasks_timeline, leftmost);
}
```

1. 从红黑树中找到 se 所应该在的位置
1. 以 se->vruntime 值为键值进行红黑树结点的比较
1. 将新进程的节点加入到红黑树中
1. 为新插入的结点进行着色

### **set_next_entity**

set_next_entity 会调用 __dequeue_entity 将下一个选择的进程从 CFS 队列的红黑树中删除，然后将 CFS 队列的 curr 指向进程的调度实体。

## **进程上下文切换**

理解了下一个进程的选择后，就需要做当前进程和所选进程的上下文切换。

Linux 内核用函数 context_switch 进行进程的上下文切换，进程上下文切换主要涉及到两部分：进程地址空间切换和处理器状态切换：



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/P2A2bdysMoAX70xThHqcRn5bnAh.png)



* **进程的地址空间切换**



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/GpGfbSTaLoO8jax15G2cUhhYnfb.png)



将下一个进程的 pgd 虚拟地址转化为物理地址存放在 ttbr0_el1 中(这是用户空间的页表基址寄存器)，当访问用户空间地址的时候 mmu 会通过这个寄存器来做遍历页表获得物理地址。完成了这一步，也就完成了进程的地址空间切换，确切的说是进程的虚拟地址空间切换。

* **寄存器状态切换**



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/TLo2bmfFEoFVI1xOcNxc8LqDnPc.png)



其中 x19-x28 是 arm64 架构规定需要调用保存的寄存器，可以看到处理器状态切换的时候将前一个进程（prev）的 x19-x28，fp,sp,pc 保存到了进程描述符的 cpu_contex 中，然后将即将执行的进程 (next) 描述符的 cpu_contex 的 x19-x28，fp,sp,pc 恢复到相应寄存器中，而且将 next 进程的进程描述符 task_struct 地址存放在 sp_el0 中，用于通过 current 找到当前进程，这样就完成了处理器的状态切换。

本文参与 [腾讯云自媒体分享计划 ](https://cloud.tencent.com/developer/support-plan)，分享自微信公众号。

原始发表：2021-12-13，如有侵权请联系 [cloudcommunity@tencent.com ](https://mailto:cloudcommunity@tencent.com)删除

