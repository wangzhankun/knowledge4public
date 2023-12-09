---
{"dg-publish":true,"date":"2023-12-09","time":"20:40","progress":"进行中","tags":["OS"],"permalink":"/找工作/操作系统/深入理解Linux线程同步(1.0)_empty macro or function name_城中之城的博客-CSDN博客/","dgPassFrontmatter":true}
---



# 深入理解Linux线程同步(1.0)_empty macro or function name_城中之城的博客-CSDN博客

# 深入理解Linux线程同步(1.0)



**推荐阅读：**[操作系统导论](https://blog.csdn.net/orangeboyye/article/details/125270782)


#   一、概念解析

我们在工作中会经常遇到 [线程同步 ](https://so.csdn.net/so/search?q=%E7%BA%BF%E7%A8%8B%E5%90%8C%E6%AD%A5&spm=1001.2101.3001.7020)，那么到底什么是线程同步呢，线程同步的本质是什么，线程同步的方法又有哪些，为什么会有这些方法呢？在回答这些问题之前，我们先做几个名词解释，以便建立共同的概念基础。


##   1.1 名词解释

**CPU：**本文中的CPU都是指逻辑CPU。
**UP：**单处理器(单CPU)。
**SMP：**对称多处理器(多CPU)。
**线程、执行流：**线程的本质是一个执行流，但执行流不仅仅有线程，还有ISR、softirq、tasklet，都是执行流。本文中说到线程一般是泛指各种执行流，除非是在需要区分不同执行流时，线程才特指狭义的线程。
**并发、并行：**并发是指线程在宏观上表现为同时执行，微观上可能是同时执行也可能是交错执行，并行是指线程在宏观上是同时执行，微观上也是同时执行。
**伪并发、真并发：**伪并发就是微观上是交错执行的并发，真并发就是并行。UP上只有伪并发，SMP上既有伪并发也有真并发。
**临界区：**访问相同数据的代码段，如果可能会在多个线程中并发执行，就叫做临界区，临界区可以是一个代码段被多个线程并发执行，也可以是多个不同的代码段被多个线程并发执行。
**同步：**首先线程同步的同步和同步异步的同步，不是一个意思。线程同步的同步，本文按照字面意思进行解释，同步就是统一步调、同时执行的意思。
**线程同步现象：**线程并发过程中如果存在临界区并发执行的情况，就叫做线程同步现象。
**线程防同步机制：**如果发生线程同步现象，由于临界区会访问共同的数据，程序可能就会出错，因此我们要防止发生线程同步现象，也就是防止临界区并发执行的情况，为此我们采取的防范措施叫做线程防同步机制。


##   1.2 线程同步与防同步

为什么线程同步叫线程同步，不叫线程防同步，叫线程同步给人的感觉好像就是要让线程同时执行的意思啊。但是实际上线程同步是让临界区不要并发执行的意思，不管你们俩谁先执行，只要错开，谁先谁后执行都可以。所以本文后面都采用线程防同步机制、防同步机制等词。

我小时候一直有个疑惑，感冒药为啥叫感冒药，感冒药是让人感冒的药啊，不是应该叫治感冒药才对吗，治疗感冒的药。后来一想，就没有让人感冒的药，所以感冒药表达的就是治疗感冒的药，没必要加个治字。但是同时还有一种药，叫老鼠药，是治疗老鼠的药吗，不是啊，是要毒死老鼠的药，因为没有人会给老鼠治病。不过我们那里也有把老鼠药叫做害老鼠药的，加个害字，意思更明确，不会有歧义。

**因此本文用了两个词，同步现象、防同步机制，使得概念更加清晰明确。**

说了这么多就是为了阐述一个非常简单的概念，就是不能同时操作相同的数据，因为可能会出错，所以我们要想办法防止，这个方法我们把它叫做线程防同步。

还有一个词是竞态条件(race condition)，很多关于线程同步的书籍文档中都有提到，但是我一直没有理解是啥意思。竞态条件，条件，线程同步和条件也没啥关系啊；竞态，也不知道是什么意思。再看它的英文，condition有情况的意思，race有赛跑、竞争的意思，是不是要表达赛跑情况、竞争现象，想说两个线程在竞争赛跑，看谁能先访问到公共数据。我发现没有竞态条件这个词对我们理解线程同步问题一点影响都没有，有了这个词反而不明所以，所以我们就忽略这个词。


#   二、线程防同步方法

在我们理解了 **同步现象、防同步机制**这两个词后，下面的内容就很好理解了。同步现象是指同时访问相同的数据，那么如何防止呢，我不让你同时访问相同的数据不就可以了嘛。因此防同步机制有三大类方法，分别是从时间上防同步、从空间上防同步、事后防同步。从时间上和空间上防同步都比较好理解，事后防同步的意思是说我先不防同步，先把临界区走一遍再说，然后回头看刚才有没有发生同步现象，如果有的话，就再重新走一遍临界区，直到没有发生同步现象为止。下面我们对这三类方法进行一一解析。


##   2.1 时间上防同步

我不让你们同时进入临界区，这样就不会同时操作相同的数据了，有三种方法：

**1.原子操作**
对于个别特别简单特别短的临界区，CPU会提供一些原子指令，在一条指令中把多个操作完成，两个原子指令必然一个在前一个在后地执行，不可能同时执行。原子指令能防伪并发和真并发，适用于UP和SMP。

**2.加锁**
对于大部分临界区来说，代码都比较复杂，CPU不可能都去实现原子指令，因此可以在临界区的入口处加锁，同一时间只能有一个线程进入，获得锁的线程进入，在临界区的出口处再释放锁。未获得锁的线程在外面等待，等待的方式有两种，忙等待的叫做 [自旋锁 ](https://so.csdn.net/so/search?q=%E8%87%AA%E6%97%8B%E9%94%81&spm=1001.2101.3001.7020)，休眠等待的叫做阻塞锁。根据临界区内的数据读写操作不同，锁又可以分为单一锁和读写锁，单一锁不区分读者写者，所有用户都互斥；读写锁区分读者和写者，读者之间可以并行，写者与读者、写者与写者之间是互斥的。自旋锁有单一锁和读写锁，阻塞锁也有单一锁和读写锁。自旋锁只能防真并发，适用于SMP；休眠锁能防伪并发和真并发，适用于UP和SMP。

**3.临时禁用伪并发**
对于某些由于伪并发而产生的同步问题，可以通过在临界区的入口处禁用此类伪并发、在临界区的出口处再恢复此类伪并发来解决。这种方式显然只能防伪并发，适用于UP和SMP上的单CPU。而自旋锁只能防真并发，所以在SMP上经常会同时使用这两种方法，同时防伪并发和真并发。关于自旋锁与禁用伪并发的结合使用，请参看 [《深入理解Linux自旋锁》 ](https://blog.csdn.net/orangeboyye/article/details/125488951)的6.2节。

临时禁用伪并发有三种情况：

a.禁用中断
如果线程和中断、软中断和中断之间会访问公共数据，那么在前者的临界区内可以临时禁用后者，也就是禁用中断，达到防止伪并发的目的。在后者的临界区内不用采取措施，因为前者不能抢占后者，但是后者能抢占前者。前者一般会同时使用禁中断和自旋锁，禁中断防止伪并发，自旋锁防止真并发。
b.禁用软中断
如果线程和软中断会访问公共数据，那么在前者的临界区内禁用后者，也就是禁用软中断，可以达到防止伪并发的目的。后者不用采取任何措施，因为前者不会抢占后者。前者也可以和自旋锁并用，同时防止伪并发和真并发。
c.禁用抢占
如果线程和线程之间会访问公共数据，那么可以在临界区内禁用抢占，达到防止伪并发的目的。禁用抢占也可以和自旋锁并用，同时防止伪并发和真并发。


##   2.2 空间上防同步

你们可以同时，但是我不让你们访问相同的数据，有两种方法：

**1. 数据分割**
把大家都要访问的公共数据分割成N份，各访问各的。这也有两种情况：
a. 在SMP上如果多个CPU要经常访问一个全局数据，那么可以把这个数据拆分成NR_CPU份，每个CPU只访问自己对应的那份，这样就不存在并发问题了，这个方法叫做 per-CPU 变量，只能防真并发，适用于SMP，需要和禁用抢占配合使用。
b. TLS，每个线程都用自己的局部数据，这样就不存在并发问题了，能防真并发和伪并发，适用于UP和SMP。

**2. 数据复制**
RCU，只适用于用指针访问的动态数据。读者复制指针，然后就可以随意读取数据了，所有的读者可以共同读一份数据。写者复制数据，然后就可以随意修改复制后的数据了，因为这份数据是私有的。不过修改完数据之后要修改指针指向最新的数据，修改指针的这个操作需要是原子的。对于读者来说，它是复制完指针之后用自己的私有指针来访问数据的，所以它访问的要么是之前的数据，要么是修改之后的数据，而不会是不一致的数据。RCU不仅能实现读者之间的同时访问，还能实现读者与一个写者的同时访问，可谓是并发性非常高。RCU对于读者端的开销非常低、性能非常高。RCU能防伪并发和真并发，适用于UP和SMP。


##   2.3 事后防同步

不去积极预防并发，而是假设不存在并发，直接访问数据。访问完了之后再检查刚才是否有并发发生，如果有就再重来一遍，一直重试，直到没有并发发生为止。这就是内核里面的序列锁seqlock，能防伪并发和真并发，适用于UP和SMP。

下面我们来画张图总结一下：

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/HpCdbaEmToKgQCxweLUcPJYknlb.png)





#   三、 [原子操作](https://so.csdn.net/so/search?q=%E5%8E%9F%E5%AD%90%E6%93%8D%E4%BD%9C&spm=1001.2101.3001.7020)

我们在刚开始学习线程同步时，经常用来举的一个例子就是，就连一个简单的i++操作都是线程不安全的。i++对于源码来说已经是非常简单的语句了，但是它编译成机器码之后有三个指令，把数据从内存加载到寄存器，把寄存器加1，把寄存器的值加1。如果有两个线程同时执行i++话，就会出问题，比如i最开始等于0，每个线程都循环一万次i++，我们期望最后的结果是两万，但是实际上最后的结果是不到两万的。对于UP来说，两个线程轮流执行，如果线程切换的点落在三条指令之间就会出问题。对于SMP来说多个CPU同时执行更会出问题。为此我们可以采取的办法可以是每次i++都加锁，这样做当然可以，不过这么做有点杀鸡用牛刀了。很多CPU专门为这种基本的整数操作提供了原子指令。


##   3.1 int原子操作

硬件提供的都是直接对整数的原子操作，但是在Linux内核里并不是直接对一个int类型进行原子操作，而是对一个封装后的数据进行操作。本质上还是对int进行操作，那么为什么要做这么一层封装呢？主要是为了接口语义，大家一看到一个变量是atomic_t类型的，大家立马就明白这是一个原子变量，不能使用普通加减操作进行运算，要使用专门的接口函数来操作才对。

```C
typedef struct {
        int counter;
} atomic_t;
```

那么对于 atomic_t的原子操作都有哪些呢？

|Atomic Integer Operation |Description |
|---|---|
|`ATOMIC_INIT(int i)` |At declaration, initialize to i |
|`int atomic_read(atomic_t *v)` |Atomically read the integer value of v |
|`void atomic_set(atomic_t *v, int i) `|Atomically set v equal to i. |
|`void atomic_add(int i, atomic_t *v) `|Atomically add i to v |
|`void atomic_sub(int i, atomic_t *v) `|Atomically subtract i from v |
|`void atomic_inc(atomic_t *v)` |Atomically add one to v |
|`void atomic_dec(atomic_t *v)` |Atomically subtract one from v |
|`int atomic_sub_and_test(int i, atomic_t *v)` |Atomically subtract i from v and return true if the result is zero; otherwise false. |
|`int atomic_add_negative(int i, atomic_t *v)` |Atomically add i to v and return true if the result is negative; otherwise false. |
|`int atomic_add_return(int i, atomic_t *v)` |Atomically add i to v and return the result. |
|`int atomic_sub_return(int i, atomic_t *v)` |Atomically subtract i from v and return the result. |
|`int atomic_dec_and_test(atomic_t *v)` |Atomically decrement v by one and return true if zero; false otherwise |
|`int atomic_inc_and_test(atomic_t *v)` |Atomically increment v by one and return true if the result is zero; false otherwise. |


##   3.2 long原子操作

如果上面的int类型(32位)不能满足我们的原子操作需求，系统还为我们定义了64位的原子变量。

```C
typedef struct {
        s64 counter;
} atomic64_t;
```

同样的也为我们提供了一堆原子接口：

|Atomic Integer Operation |Description |
|---|---|
|ATOMIC64_INIT(int i) |At declaration, initialize to i |
|``int atomic64_read(atomic_t *v)`` |Atomically read the integer value of v |
|``void atomic64_set(atomic_t *v, int i)`` |Atomically set v equal to i. |
|``void atomic64_add(int i, atomic_t *v)`` |Atomically add i to v |
|``void atomic64_sub(int i, atomic_t *v)`` |Atomically subtract i from v |
|``void atomic64_inc(atomic_t *v) ``|Atomically add one to v |
|``void atomic64_dec(atomic_t *v)`` |Atomically subtract one from v |
|``int atomic64_sub_and_test(int i, atomic_t *v) ``|Atomically subtract i from v and return true if the result is zero; otherwise false. |
|``int atomic64_add_negative(int i, atomic_t *v)`` |Atomically add i to v and return true if the result is negative; otherwise false. |
|``int atomic64_add_return(int i, atomic_t *v)`` |Atomically add i to v and return the result. |
|``int atomic64_sub_return(int i, atomic_t *v)`` |Atomically subtract i from v and return the result. |
|``int atomic64_dec_and_test(atomic_t *v)`` |Atomically decrement v by one and return true if zero; false otherwise |
|``int atomic64_inc_and_test(atomic_t *v)`` |Atomically increment v by one and return true if the result is zero; false otherwise. |


##   3.3 bit原子操作

系统还给我们提供了位运算的原子操作，不过并没有封装数据类型，而是操作一个void * 指针所指向的数据，我们要操作的位数要在我们希望的数据之内，这点是由我们自己来保证的。

|Atomic Bitwise Operation |Description |
|---|---|
|`void set_bit(int nr, void *addr)` |Atomically set the nr-th bit starting from addr. |
|`void clear_bit(int nr, void *addr)` |Atomically clear the nr-th bit starting from addr. |
|`void change_bit(int nr, void *addr)` |Atomically flip the value of the nr-th bit starting from addr. |
|`int test_and_set_bit(int nr, void *addr)` |Atomically set the nr-th bit starting from addr and return the previous value. |
|`int test_and_clear_bit(int nr, void *addr)` |Atomically clear the nr-th bit starting from addr and return the previous value. |
|`int test_and_change_bit(int nr, void *addr)` |Atomically flip the nr-th bit starting from addr and return the previous value. |
|`int test_bit(int nr, void *addr)` |Atomically return the value of the nrth bit starting from addr. |
有了原子操作，我们对这些简单的基本运算就不用使用加锁机制了，就可以提高效率。


#   四、加锁机制

有很多临界区，并不是一些简单的整数运算，不可能要求硬件都给提供原子操作。为此，我们需要锁机制，在临界区的入口进行加锁操作，加到锁的才能进入临界区进行操作，加不到锁的要一直在临界区外面等候。等候的方式有两种，一种是忙等待，就是自旋锁，一种是休眠等待，就是阻塞锁，阻塞锁在Linux里面的实现叫做互斥锁。


##   4.1 锁的底层原理

我们该如何实现一个锁呢，下面我们尝试直接用软件来实现试试，代码如下：

```C
int lock = 0;

void lock(int * lock){
start:
        if(*lock == 0)
                *lock = 1;
        else{
                wait();
                goto start;
        }
}

void unlock(int * lock){
        *lock = 0;
        wakeup();
}
```

可以看到这个锁的实现逻辑很简单，定义一个整数作为锁，0代表没人持锁，1代表有人持锁。我们先判断锁的值，如果是0代表没人持锁，我们给锁赋值1，代表我们获得了锁，然后函数返回，就可以进入临界区了。如果锁是1，代表有人已经持有了锁，此时我们就需要等待，等待函数wait，可以用忙等待，也可以用休眠等待。释放锁的时候把锁设为0，然后wakeup其他线程或者为空操作。被唤醒的线程从wait中醒来，然后又重走加锁流程。但是这里面有个问题，就是加锁操作也是个临界区，如果两个线程在两个CPU上同时执行到加锁函数，双方都检测到锁是0，然后都把锁置为1，都加锁成功，这不是出问题了吗。锁就是用来保护临界区的，但是加锁本身也是临界区，也需要保护，该怎么办呢？唯一的方法就是求助于硬件，让加锁操作成为原子操作，X86平台提供了CAS指令来实现这个功能。CAS，Compare and Swap，比较并交换，它的接口逻辑是这样的：

```C
int cas(int * p, old_value, new_value)
```

如果p位置的值等于old_value，就把p位置的值设置为new_value，并返回1，否则返回0。关键就在于cas它是硬件实现的，是原子的。这样我们就可以用cas指令来实现锁的逻辑，如下所示：

```C
int lock = 0;

void lock(int * lock){
start:
        if(cas(lock, 0, 1))
                return;
        else{
                wait();
                goto start;
        }
}

void unlock(int * lock){
        *lock = 0;
        wakeup();
}
```

这样一个最基础的锁机制就实现了。


##   4.2 简单自旋锁

为什么在这里要先讲简单自旋锁呢？因为互斥锁、信号量这些锁的内部实现都用了自旋锁，所以先把自旋锁的逻辑讲清楚才能继续讲下去。为什么是简单自旋锁呢，因为自旋锁现在已经发展得很复杂了，所以这里就是讲一下自旋锁的简单版本，因为它们的基本逻辑是一致的。自旋锁由于在加锁失败时是忙等待，所以不用考虑等待队列、睡眠唤醒的问题，所以实现比较简单，下面是简单自旋锁的实现代码：

```C
int lock = 0;

void spin_lock(int * lock){
        while(!cas(lock, 0, 1))
}

void spin_unlock(int * lock){
        *lock = 0;
}
```

可以看到简单自旋锁的代码是相当简单，加锁的时候不停地尝试加锁，一直失败一直加，直到成功才返回。释放锁的时候更简单，直接把锁置为0就可以了。此时如果有其它自旋锁在自旋，由于锁已经变成了0，所以就会加锁成功，结束自旋。注意这个代码只是自旋锁的逻辑演示，并不是真正的自旋锁实现。内核里的自旋锁经历了好几代的发展，现在已经变的非常复杂了，具体内容请参看 [《深入理解Linux自旋锁》 ](https://blog.csdn.net/orangeboyye/article/details/125488951)。


##   4.3 互斥锁

互斥锁是休眠锁，加锁失败时要把自己放入等待队列，释放锁的时候要考虑唤醒等待队列的线程。互斥锁的定义如下(删除了一些配置选项)：

```C
struct mutex {
        atomic_long_t                owner;
        raw_spinlock_t                wait_lock;
        struct list_head        wait_list;
};
```

可以看到互斥锁的定义有atomic_long_t owner，这个和我们之前定义的int lock是相似的，只不过这里是个加强版，0代表没加锁，加锁的时候是非0，而不是简单的1，而是记录的是加锁的线程。然后是自旋锁和等待队列，自旋锁是用来保护等待队列的。这里的自旋锁为什么要用raw_spinlock_t呢，它和spinlock_t有什么区别呢？在标准的内核版本下是没有区别的，如果打了RTLinux补丁之后它们就不一样了，spinlock_t会转化为阻塞锁，raw_spinlock_t还是自旋锁，如果需要在任何情况下都要自旋的话请使用raw_spinlock_t。下面我们看一下它的加锁操作：

```C
void __sched mutex_lock(struct mutex *lock)
{
        might_sleep();

        if (!__mutex_trylock_fast(lock))
                __mutex_lock_slowpath(lock);
}
static __always_inline bool __mutex_trylock_fast(struct mutex *lock)
{
        unsigned long curr = (unsigned long)current;
        unsigned long zero = 0UL;

        if (atomic_long_try_cmpxchg_acquire(&lock->owner, &zero, curr))
                return true;

        return false;
}
```

可以看到加锁时先尝试直接加锁，用的就是CAS原子指令(x86的CAS指令叫做cmpxchg)。如果owner是0，代表当前锁是开着的，就把owner设置为自己(也就是当前线程，struct task_struct * 强转为 ulong)，代表自己成为这个锁的主人，也就是自己加锁成功了，然后返回true。如果owner不为0的话，代表有人已经持有锁了，返回false，后面就要走慢速路径了，也就是把自己放入等待队列里休眠等待。下面看看慢速路径的代码是怎么实现的：

```C
static noinline void __sched
__mutex_lock_slowpath(struct mutex *lock)
{
        __mutex_lock(lock, TASK_UNINTERRUPTIBLE, 0, NULL, _RET_IP_);
}

static int __sched
__mutex_lock(struct mutex *lock, unsigned int state, unsigned int subclass,
             struct lockdep_map *nest_lock, unsigned long ip)
{
        return __mutex_lock_common(lock, state, subclass, nest_lock, ip, NULL, false);
}

static __always_inline int __sched
__mutex_lock_common(struct mutex *lock, unsigned int state, unsigned int subclass,
                    struct lockdep_map *nest_lock, unsigned long ip,
                    struct ww_acquire_ctx *ww_ctx, const bool use_ww_ctx)
{
        struct mutex_waiter waiter;
        int ret;

        raw_spin_lock(&lock->wait_lock);
        waiter.task = current;
        __mutex_add_waiter(lock, &waiter, &lock->wait_list);

        set_current_state(state);
        for (;;) {
                bool first;
                if (__mutex_trylock(lock))
                        goto acquired;

                raw_spin_unlock(&lock->wait_lock);
                schedule_preempt_disabled();

                first = __mutex_waiter_is_first(lock, &waiter);
                set_current_state(state);
                if (__mutex_trylock_or_handoff(lock, first))
                        break;

                raw_spin_lock(&lock->wait_lock);
        }

acquired:
        __set_current_state(TASK_RUNNING);
        __mutex_remove_waiter(lock, &waiter);
        raw_spin_unlock(&lock->wait_lock);

        return ret;
}

static void
__mutex_add_waiter(struct mutex *lock, struct mutex_waiter *waiter,
                   struct list_head *list)
{
        debug_mutex_add_waiter(lock, waiter, current);

        list_add_tail(&waiter->list, list);
        if (__mutex_waiter_is_first(lock, waiter))
                __mutex_set_flag(lock, MUTEX_FLAG_WAITERS);
}
```

可以看到慢速路径最终会调用函数__mutex_lock_common，这个函数本身是很复杂的，这里进行了大量的删减，只保留了核心逻辑。函数先加锁mutex的自旋锁，然后把自己放到等待队列上去，然后就在无限for循环中休眠并等待别人释放锁并唤醒自己。For循环的入口处先尝试加锁，如果成功就goto acquired，如果不成功就释放自旋锁，并调用schedule_preempt_disabled，此函数就是休眠函数，它会调度其它进程来执行，自己就休眠了，直到有人唤醒自己才会醒来继续执行。别人释放锁的时候会唤醒自己，这个我们后面会分析。当我们被唤醒之后会去尝试加锁，如果加锁失败，再次来到for循环的开头处，再试一次加锁，如果不行就再走一次休眠过程。为什么我们加锁会失败呢，因为有可能多个线程同时被唤醒来争夺锁，我们不一定会抢锁成功。抢锁失败就再去休眠，最后总会抢锁成功的。

把自己加入等待队列时会设置flag MUTEX_FLAG_WAITERS，这个flag是设置在owner的低位上去，因为task_struct指针至少是L1_CACHE_BYTES对齐的，所以最少有3位可以空出来做flag。

下面我们再来看一下释放锁的流程：

```C
void __sched mutex_unlock(struct mutex *lock)
{        if (__mutex_unlock_fast(lock))
                return;
        __mutex_unlock_slowpath(lock, _RET_IP_);
}

static __always_inline bool __mutex_unlock_fast(struct mutex *lock)
{
        unsigned long curr = (unsigned long)current;

        return atomic_long_try_cmpxchg_release(&lock->owner, &curr, 0UL);
}
```

解锁的时候先尝试快速解锁，快速解锁的意思是没有其它在等待队列里，可以直接释放锁。怎么判断等待队列里没有线程在等待呢，这就是前面设置的MUTEX_FLAG_WAITERS的作用了。如果设置了这个flag，lock->owner 和 curr就不会相等，直接释放锁就会失败，就要走慢速路径。慢速路径的代码如下：

```C
static noinline void __sched __mutex_unlock_slowpath(struct mutex *lock, unsigned long ip)
{
        struct task_struct *next = NULL;
        DEFINE_WAKE_Q(wake_q);
        unsigned long owner;

        owner = atomic_long_read(&lock->owner);
        for (;;) {
                if (atomic_long_try_cmpxchg_release(&lock->owner, &owner, __owner_flags(owner))) {
                        if (owner & MUTEX_FLAG_WAITERS)
                                break;
                }
        }

        raw_spin_lock(&lock->wait_lock);
        if (!list_empty(&lock->wait_list)) {
                struct mutex_waiter *waiter =
                        list_first_entry(&lock->wait_list,
                                         struct mutex_waiter, list);
                next = waiter->task;
                wake_q_add(&wake_q, next);
        }
        raw_spin_unlock(&lock->wait_lock);
        wake_up_q(&wake_q);
}
```

上述代码进行了一些删减。可以看出上述代码会先释放锁，然后唤醒等待队列里面的第一个等待者。


##   4.4 信号量

信号量与互斥锁有很大的不同，互斥锁代表只有一个线程能同时进入临界区，而信号量是个整数计数，代表着某一类资源有多少个，能同时让多少个线程访问这类资源。信号量也没有加锁解锁操作，信号量类似的操作叫做down和up，down代表获取一个资源，up代表归还一个资源。

下面我们先看一下信号量的定义：

```C
struct semaphore {
        raw_spinlock_t                lock;
        unsigned int                count;
        struct list_head        wait_list;
};

#define __SEMAPHORE_INITIALIZER(name, n)                                \{                                                                        \
        .lock                = __RAW_SPIN_LOCK_UNLOCKED((name).lock),        \
        .count                = n,                                                \
        .wait_list        = LIST_HEAD_INIT((name).wait_list),                \}

static inline void sema_init(struct semaphore *sem, int val)
{
        *sem = (struct semaphore) __SEMAPHORE_INITIALIZER(*sem, val);
}
```

可以看出信号量和互斥锁的定义很相似，都有一个自旋锁，一个等待队列，不同的是信号量没有owner，取而代之的是count，代表着某一类资源的个数，而且自旋锁同时保护着等待队列和count。信号量初始化时要指定count的大小。

我们来看一下信号量的down操作(获取一个资源)：

```C
void down(struct semaphore *sem)
{
        unsigned long flags;

        might_sleep();
        raw_spin_lock_irqsave(&sem->lock, flags);
        if (likely(sem->count > 0))
                sem->count--;
        else
                __down(sem);
        raw_spin_unlock_irqrestore(&sem->lock, flags);
}

static noinline void __sched __down(struct semaphore *sem)
{
        __down_common(sem, TASK_UNINTERRUPTIBLE, MAX_SCHEDULE_TIMEOUT);
}

static inline int __sched __down_common(struct semaphore *sem, long state,
                                                                long timeout)
{
        struct semaphore_waiter waiter;

        list_add_tail(&waiter.list, &sem->wait_list);
        waiter.task = current;
        waiter.up = false;

        for (;;) {
                if (signal_pending_state(state, current))
                        goto interrupted;
                if (unlikely(timeout <= 0))
                        goto timed_out;
                __set_current_state(state);
                raw_spin_unlock_irq(&sem->lock);
                timeout = schedule_timeout(timeout);
                raw_spin_lock_irq(&sem->lock);
                if (waiter.up)
                        return 0;
        }

 timed_out:
        list_del(&waiter.list);
        return -ETIME;

 interrupted:
        list_del(&waiter.list);
        return -EINTR;
}
```

可以看出我们会先持有自旋锁，然后看看count是不是大于0，大于0的话代表资源还有剩余，我们直接减1，代表占用一份资源，就可以返回了。如果不大于0的话，代表资源没有了，我们就进去等待队列等待。

我们再来看看up操作(归还资源)：

```C
void up(struct semaphore *sem)
{
        unsigned long flags;

        raw_spin_lock_irqsave(&sem->lock, flags);
        if (likely(list_empty(&sem->wait_list)))
                sem->count++;
        else
                __up(sem);
        raw_spin_unlock_irqrestore(&sem->lock, flags);
}

static noinline void __sched __up(struct semaphore *sem)
{
        struct semaphore_waiter *waiter = list_first_entry(&sem->wait_list,
                                                struct semaphore_waiter, list);
        list_del(&waiter->list);
        waiter->up = true;
        wake_up_process(waiter->task);
}
```

先加锁自旋锁，然后看看等待队列是否为空，如果为空的话直接把count加1就可以了。如果不为空的话，则代表有人在等待资源，资源就不加1了，直接唤醒队首的线程来获取。


#   五、per-CPU 变量

前面讲的原子操作和加锁机制都是从时间上防同步的，现在我们开始讲空间上防同步，先来讲讲per-CPU变量。如果我们要操作的数据和当前CPU是密切相关的，不同的CPU可以操作不同的数据，那么我们就可以把这个变量定义为per-CPU变量，每个CPU就可以各访问各的，互不影响了。这个方法可以防止多个CPU之间的真并发，但是同一个CPU上如果有伪并发，还是会出问题，所以还需要禁用伪并发。per-CPU变量的定义和使用方法如下表所示：

|Macro or function name |Description |
|---|---|
|`DEFINE_PER_CPU(type, name)` |Statically allocates a per-CPU array called name of type data structures |
|`per_cpu(name, cpu) `|Selects the element for CPU cpu of the per-CPU array name |
|`_ _get_cpu_var(name)` |Selects the local CPU’s element of the per-CPU array name |
|`get_cpu_var(name)` |Disables kernel preemption, then selects the local CPU’s element of the per-CPU array name |
|`put_cpu_var(name) `|Enables kernel preemption (name is not used) |
|`alloc_percpu(type)` |Dynamically allocates a per-CPU array of type data structures and returns its address |
|`free_percpu(pointer)` |Releases a dynamically allocated per-CPU array at address pointer |
|`per_cpu_ptr(pointer, cpu)` |Returns the address of the element for CPU cpu of the per-CPU array at address pointer |


#   六、RCU 简介

RCU是一种非常巧妙的空间防同步方法。首先它只能用于用指针访问的动态数据。其次它采取读者和写者分开的方法，读者读取数据要先复制指针，用这个复制的指针来访问数据，这个数据是只读的，不会被修改，很多读者可以同时来访问。写者并不去直接更改数据，而是先申请一块内存空间，把数据都复制过来，在这个复制的数据上修改数据，由于这块数据是私有的，所以可以随意修改，也不用加锁。修改完了之后，写者要原子的修改指针的值，让它指向自己新完成的数据。这对于读者来说是没有影响的，因为读者已经复制了指针，所以读者读的还是原来的数据没有变，新来的读者会复制新的指针，访问新的数据，读者访问的一直都是一致性的数据，不会访问到修改一半的数据。RCU的难点在于，原有的数据怎么回收，当写者更新指针之后，原先的数据就过期了，当所有老的读者都离开临界区之后，这个数据的内存需要被释放，写者需要判断啥时候老的读者全都离开临界区了，才能去释放老的数据。关于RCU详细的实现原理，请参看《深入理解Linux RCU》(还没写)。


#   七、序列锁

除了前面讲的时间防同步、空间防同步，Linux还有一种非常巧妙的防同步方法，那就是不妨了事后再补救，我第一次看到这个方法的时候，真是拍案叫绝，惊叹不已，还能这么做。这种方法叫做序列锁，它的思想就好比是，我家里也不锁门了，小偷偷就偷吧，偷了我就再报警把东西找回来。反正小偷又不是天天来我家偷东西，小偷来的次数非常少，我天天锁门太费劲了。我每天早上看一下啥东西丢了没，丢了就报警把东西找回来。当然这个类比并不完全像，只是大概逻辑比较像，下面我们就来讲一讲序列锁的做法。序列锁区分读者和写者，读者可以并行，写者还是需要互斥的，读者和写者之间也可以并行，所以当读者很频繁，写者很偶发的时候就适合用序列锁。这个锁有一个序列号，初始值是0，写者进入临界区时把这个序列号加1，退出时再加1，读者读之前先获取这个锁的序列号，如果是奇数说明有写者在临界区，就不停地获取序列号，直到序列号为偶数为止。然后读者进入临界区进行读操作，然后退出临界区的时候再读取一下序列号。如果和刚才获取的序列号不一样，说明有写者刚才进来过，再重新走一遍刚才的操作。如果序列号还不一样就一直重复，直到序列号一样为止。

下面我们先来看看序列锁的定义：

```C
typedef struct seqcount {
        unsigned sequence;
} seqcount_t;

typedef struct {
        seqcount_spinlock_t seqcount;
        spinlock_t lock;
} seqlock_t;
```

seqlock_t包含一个自旋锁和一个seqcount_spinlock_t，seqcount_spinlock_t经过一些复杂的宏定义包含了seqcount_t，所以可以简单地认为seqlock_t包含一个自旋锁和一个int序列号。

下面我们看一下写者的操作：

```C
static inline void write_seqlock(seqlock_t *sl)
{
        spin_lock(&sl->lock);
        do_write_seqcount_begin(&sl->seqcount.seqcount);
}

static inline void write_sequnlock(seqlock_t *sl)
{
        do_write_seqcount_end(&sl->seqcount.seqcount);
        spin_unlock(&sl->lock);
}
```

写者的操作很简单，就是用自旋锁实现互斥，然后加锁解释的时候都把序列号增加1。

下面看读者的操作：

```C
static inline unsigned read_seqbegin(const seqlock_t *sl)
{
        unsigned ret = read_seqcount_begin(&sl->seqcount);

        kcsan_atomic_next(0);  /* non-raw usage, assume closing read_seqretry() */
        kcsan_flat_atomic_begin();
        return ret;
}

static inline unsigned read_seqretry(const seqlock_t *sl, unsigned start)
{
        /*
         * Assume not nested: read_seqretry() may be called multiple times when
         * completing read critical section.
         */
        kcsan_flat_atomic_end();

        return read_seqcount_retry(&sl->seqcount, start);
}
```

读者进入临界区之前先通过read_seqbegin获取一个序列号，在临界区的时候调用read_seqretry看看是否需要重走一遍临界区。我们下面看一下内核里使用序列锁的一个例子：

```C
struct dentry *d_lookup(const struct dentry *parent, const struct qstr *name)
{
        struct dentry *dentry;
        unsigned seq;

        do {
                seq = read_seqbegin(&rename_lock);
                dentry = __d_lookup(parent, name);
                if (dentry)
                        break;
        } while (read_seqretry(&rename_lock, seq));
        return dentry;
}

void d_move(struct dentry *dentry, struct dentry *target)
{
        write_seqlock(&rename_lock);
        __d_move(dentry, target, false);
        write_sequnlock(&rename_lock);
}
```

可以看到写者使用序列锁和正常的使用方法是一样的，读者使用序列锁一般都是配合do while循环一起使用。


#   八、总结回顾

通过本文，我们明白了线程同步的本质，了解了线程防同步的基本逻辑和具体方法。防同步就是防止多个执行流同时访问相同的数据，所以我们可以从两点来防，一个是同时(时间上防同步)，一个是相同的数据(空间上防同步)。时间上防同步我们采取的方法有原子操作，通过硬件来防止同时，加锁机制，软件方法来防同时，还有禁用伪并发，防止宏观上的同时微观上的交错。空间防同步我们采取的方法有数据分割、per CPU变量，每个CPU值访问自己对应的数据。数据复制，RCU，读的时候复制指针，读的数据是不变的，写的时候不直接改变数据，而是先把数据复制过来，修改自己的私有副本，这样就不会有同步的问题，然后再原子地更新指针指向最新的数据。



**参考文献：**
《Linux Kernel Development》
《Understanding the Linux Kernel》
《Professional Linux Kernel Architecture》


[https://lwn.net/Kernel/Index/#Locking_mechanisms](https://lwn.net/Kernel/Index/#Locking_mechanisms)
[http://www.wowotech.net/sort/kernel_synchronization](http://www.wowotech.net/sort/kernel_synchronization)



   

显示推荐内容

