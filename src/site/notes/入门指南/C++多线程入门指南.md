---
{"dg-publish":true,"date":"2023-12-18","time":"16:05","progress":"进行中","tags":["cpp","入门指南","多线程"],"permalink":"/入门指南/C++多线程入门指南/","dgPassFrontmatter":true}
---


# C++多线程入门指南


## 声明

本文为本人原创，未经授权严禁转载。如需转载需要在文章最前面注明本文原始链接。


# 理解多线程的基本概念

## 什么是多线程

多线程（Multithreading）是一种并发编程技术，它允许在同一个程序中并发执行多个任务，从而充分利用系统的硬件资源，提高程序的性能。多线程技术的实现方式有很多种，常见的有时间片轮转法、优先级调度法和自旋锁法等。

线程是计算机科学中的一种概念，表示在进程中执行特定任务的独立执行路径。它是操作系统的基本组成部分，可以同时执行多个任务，从而提高应用程序的性能。

以下是一些线程的基本特性：

1. **并发性**：线程可以同时执行，这意味着多个任务可以同时进行，从而提高应用程序的并发性。
2. **独立性**：每个线程都有自己的栈空间，并且可以独立于其他线程运行，这意味着一个线程的错误不会影响其他线程。
3. **共享内存**：线程共享进程的内存空间，这意味着它们可以访问相同的变量和数据结构。
4. **线程创建和销毁**：线程可以通过操作系统提供的 API 创建和销毁。
5. **线程同步**：为了确保线程之间的数据一致性，我们需要使用线程同步机制，如互斥锁、信号量和条件变量等。
6. **线程调度**：操作系统负责根据一定的策略对线程进行调度，以确保它们公平地获得 CPU 时间。

线程在现代操作系统中被广泛使用，并且在许多应用程序中发挥着重要的作用。例如，在多媒体应用程序中，线程可以用于同时播放音频和视频数据。在Web 服务器中，线程可以用于同时处理多个客户机的请求。在游戏开发中，线程可以用于同时更新游戏世界的状态和渲染图形。

总之，线程是计算机科学中的一种重要概念，它可以提高应用程序的并发性和性能。

## 多线程的好处和坏处
### 好处
1. **提高程序的性能**：多线程技术可以并发执行多个任务，从而充分利用系统的硬件资源，提高程序的性能。
2. **提高程序的响应性**：多线程技术可以使程序对用户输入或外部事件做出更快的响应，因为可以同时处理多个任务。
3. **简化程序的开发**：多线程技术可以使程序的开发变得更加简单，因为可以将复杂的任务分解成多个独立的任务，然后并发执行这些任务。
### 缺点

1. **增加程序的复杂性**：多线程技术增加了程序的复杂性，因为需要考虑多个任务之间的同步和通信问题。
2. **可能导致死锁**：如果多个任务相互等待，而无法继续执行，则可能会导致死锁。
3. **需要额外的系统资源**：多线程技术需要额外的系统资源，如内存和处理器时间。

**并发**是指多个任务同时执行，而**并行**是指单个任务的多个部分同时执行。

**并发**是一种逻辑上的概念，它描述了多个任务如何交替执行，以便看起来它们是在同时执行。例如，在一个多任务操作系统中，多个程序可以同时运行，但实际上它们是在交替执行，以便每个程序都能获得处理器的使用权。

**并行**是一种物理上的概念，它描述了多个操作如何在同时执行。例如，在一个多核处理器中，多个核可以同时执行不同的指令，从而提高了处理速度。

**并发**和**并行**是两个相关的概念，但它们并不相同。**并发**是一种逻辑上的概念，而**并行**是一种物理上的概念。**并发**可以实现**并行**，但**并行**不一定能实现**并发**。

**并发**和**并行**都有各自的优缺点。**并发**的优点是它可以更容易地实现，而且它不需要特殊的硬件。**并发**的缺点是它可能会导致性能下降，因为多个任务需要共享处理器的使用权。**并行**的优点是它可以提高性能，因为多个操作可以在同时执行。**并行**的缺点是它需要特殊的硬件，而且它可能会导致编程复杂度增加。

## 多线程的应用场景

### 多核处理器

- 多核处理器可以同时执行多个任务，提高计算机的处理速度。
- 多线程可以利用多核处理器的优势，将任务分配到不同的内核上执行，提高程序的性能。

### I/O密集型应用

- I/O密集型应用需要大量的时间进行数据传输，例如文件读写、网络请求等。
- 多线程可以将I/O操作和计算任务分离，使程序可以同时进行计算和I/O操作，提高程序的吞吐量。

### GUI应用

- GUI应用需要不断地响应用户的输入，例如点击鼠标、拖动窗口等。
- 多线程可以将GUI的事件处理和计算任务分离，使程序可以同时响应用户的输入和进行计算，提高程序的响应速度。

### 并行算法

- 并行算法可以将一个任务分解成多个子任务，然后同时执行这些子任务。
- 多线程可以用来实现并行算法，提高算法的执行速度。

### 其他应用场景

- 多线程还可以用于其他应用场景，例如：
  - 游戏开发：多线程可以用来实现游戏中的物理模拟、人工智能等功能。
  - 视频编辑：多线程可以用来实现视频的编码、解码等功能。
  - 科学计算：多线程可以用来实现复杂的科学计算。



# C++多线程编程基础

## C++中的线程类

C++11 引入了 `<thread>` 头文件，其中包含了一组用于多线程编程的类和函数。最主要的类是 `std::thread`，它允许创建、控制和同步线程的执行。

`std::thread` 类用于创建和管理线程。以下是它的基本用法：
你可以通过传递一个函数及其参数来创建一个线程。这个函数将在新线程中执行。
```c++
#include <iostream>
#include <thread>

void threadFunction()
{
    // 线程执行的代码
    std::cout << "Thread running..." << std::endl;
}

void func(int x, const std::string &str) { std::cout << "Value: " << x << ", String: " << str << std::endl; }

int main()
{
    std::thread myThread(threadFunction); // 创建一个新线程
    myThread.join();                      // 等待线程执行完毕
    int value = 42;
    std::string message = "Hello, Threads!"; // 使用函数对象

    std::thread t([value, message]()
                  { std::cout << "Value: " << value << ", String: " << message << std::endl; });
    t.join();

    std::thread t1(func, value, message);

    return 0;
}
```

### 线程类的同步

线程类还提供了用于同步线程之间的访问的方法。这些方法可以防止出现竞争条件，即多个线程同时访问同一资源时可能导致的问题。

线程类提供的主要同步方法有：

* mutex：互斥量，用于保护共享资源，以防止多个线程同时访问。
* condition_variable：条件变量，用于等待某个条件满足。
* semaphore：信号量，用于限制对共享资源的访问。


## 线程同步机制

### 锁的类型

在 C++ 中，常见的锁类型有以下几种：

#### 1. `std::mutex`

- **互斥锁**：最基本的锁类型，用于实现简单的互斥访问控制。
- 提供的方法：`lock()`、`try_lock()`、`unlock()`

#### 2. `std::recursive_mutex`

- **递归锁**：允许同一线程多次获取锁，可以避免死锁。
- 提供的方法：`lock()`、`try_lock()`、`unlock()`

#### 3. `std::timed_mutex`

- **定时锁**：是 `std::mutex` 的扩展，允许在尝试获取锁时设置超时时间。
- 提供的方法：`lock()`、`try_lock_for()`、`try_lock_until()`、`unlock()`

#### 4. `std::recursive_timed_mutex`

- **定时递归锁**：结合了递归锁和定时锁的功能。
- 提供的方法：`lock()`、`try_lock_for()`、`try_lock_until()`、`unlock()`


#### 5. `std::shared_mutex` (C++17)

- **读写锁**：允许多个线程同时获取读锁（共享访问），在写锁（独占访问）被持有时，所有其他线程都被阻塞。
- 提供的方法：`lock()`、`try_lock()`、`unlock()`（C++17 新增）、`lock_shared()`、`try_lock_shared()`、`unlock_shared()`（C++17 新增）
- 
#### 互斥锁

互斥锁是一种同步原语，用于保证同一时间只有一个线程能够访问共享资源。在 C++ 中，可以使用 `std::mutex` 来创建互斥锁。

```c++
#include <iostream>
#include <thread>
#include <mutex>

std::mutex mtx;

void print_hello(int id) {
  mtx.lock();
  std::cout << "Hello from thread " << id << std::endl;
  mtx.unlock();
}

void criticalSection() {
    std::lock_guard<std::mutex> lock(mtx); // 自动锁定和解锁
    // 临界区代码
    std::cout << "Critical Section" << std::endl;
}


int main() {
  std::thread t1(print_hello, 1);
  std::thread t2(criticalSection, 2);

  t1.join();
  t2.join();

  return 0;
}
```

#### 递归锁
```c++
#include <iostream>
#include <thread>
#include <mutex>
#include <vector>

std::recursive_mutex rmtx;

void recursiveSection(int count)
{
    std::lock_guard<std::recursive_mutex> lock(rmtx);
    if (count == 5)
        std::cout << std::this_thread::get_id() << "\tCount: ";

    std::cout << count << " ";
    if (count > 0)
    {
        recursiveSection(count - 1); // 递归调用
    }
    else
        std::cout << std::endl;
}

int main()
{
    std::vector<std::thread> threads;

    for (int i = 0; i < 10; ++i)
    {
        threads.emplace_back(recursiveSection, 5);
    }

    for (auto &t : threads)
    {
        t.join();
    }

    return 0;
}

```

#### 超时锁
```c++
#include <iostream>
#include <thread>
#include <mutex>
#include <chrono>

std::timed_mutex tmtx;

void criticalSection1()
{
    if (tmtx.try_lock_for(std::chrono::milliseconds(100)))
    {
        std::cout << __FUNCTION__ << "\tLock acquired!" << std::endl;
        // 临界区代码
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
        tmtx.unlock(); // 解锁
    }
    else
    {
        std::cout << __FUNCTION__ << "\tFailed to acquire lock within timeout." << std::endl;
        // 超时处理
    }
}

void criticalSection2()
{
    if (tmtx.try_lock_until(std::chrono::steady_clock::now() + std::chrono::milliseconds(600)))
    {
        std::cout << __FUNCTION__ << "\tLock acquired!" << std::endl;
        // 临界区代码
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
        tmtx.unlock(); // 解锁
    }
    else
    {
        std::cout << __FUNCTION__ << "\tFailed to acquire lock within timeout." << std::endl;
        // 超时处理
    }
}

void criticalSection3()
{
    std::unique_lock<std::timed_mutex> lock(tmtx, std::chrono::milliseconds(100));

    if (lock.owns_lock())
    {
        std::cout << __FUNCTION__ << "\tLock acquired!" << std::endl;
        // 临界区代码
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }
    else
    {
        std::cout << __FUNCTION__ << "\tFailed to acquire lock within timeout." << std::endl;
        // 超时处理
    }
    // 在 lock 离开作用域时自动释放锁
}

int main()
{
    std::thread t1(criticalSection1);
    std::thread t2(criticalSection2);
    std::thread t3(criticalSection3);

    t1.join();
    t2.join();
    t3.join();

    return 0;
}

```

#### 共享锁
C++17 引入了 `std::shared_mutex`，它是一种支持共享访问和排他访问的读写锁。读写锁允许多个线程同时获取读锁（共享访问），但在写锁（独占访问）被持有时，所有其他线程都被阻塞。

```c++
#include <iostream>
#include <thread>
#include <mutex>
#include <shared_mutex>
#include <chrono>
#include <vector>
#include <atomic>


std::atomic<int> readCount = 0;
std::atomic<int> writeCount = 0;

std::shared_mutex smtx;
int sharedData = 0;

void writeOperation() {
    std::unique_lock<std::shared_mutex> lock(smtx); // 独占写锁
    writeCount++;

    std::this_thread::sleep_for(std::chrono::milliseconds(2)); // 模拟写操作时间
    // 写操作
    sharedData++;
    std::cout << "Write count: " << writeCount << std::endl;
    writeCount--;
}

void readOperation() {
    std::shared_lock<std::shared_mutex> lock(smtx); // 共享读锁
    readCount++;

    std::this_thread::sleep_for(std::chrono::milliseconds(2)); // 模拟读操作时间

    // 读操作
    std::cout << "readCount" << readCount.load() << "\tShared data: " << sharedData << std::endl;

    readCount--;
}

int main() {

    std::vector<std::thread> readers;
    std::vector<std::thread> writers;

    for (int i = 0; i < 500; i++) {
        readers.emplace_back(readOperation);
        if (i % 10 == 0) {
            writers.emplace_back(writeOperation);
        }
    }

    
    for (auto &t : readers) {
        t.join();
    }

    for (auto &t : writers) {
        t.join();
    }

    return 0;
}

```




### 条件变量

#### 简介
条件变量是一种同步机制，它允许线程在满足特定条件时被唤醒。它通常与互斥锁一起使用，以确保只有一个线程可以访问共享资源。条件变量是C++11标准库的一部分。

1. **同步多个线程之间的访问。** 条件变量通常用于同步多个线程之间的访问，以确保在给定时刻只有一个线程可以访问共享资源。例如，在生产者-消费者问题中，可以使用条件变量来同步生产者和消费者线程，以确保生产者只在消费者准备好接受数据时才生产数据，而消费者只在生产者准备好提供数据时才消费数据。
2. **等待事件发生。** 条件变量还可以用于等待事件发生。例如，在等待文件 I/O 操作完成或等待另一个线程完成任务时，可以使用条件变量。当事件发生时，等待的线程将被唤醒，并可以继续执行。
3. **避免繁忙等待。** 当一个线程需要等待另一个线程完成任务时，可以使用条件变量来避免繁忙等待。在繁忙等待中，等待的线程不断地轮询另一个线程的状态，直到它完成任务。这会浪费 CPU 时间，并且会导致性能下降。相比之下，条件变量允许等待的线程进入睡眠状态，直到另一个线程唤醒它。这可以节省 CPU 时间，并提高性能。
4. **实现公平锁。** 条件变量可以用于实现公平锁。公平锁是一种锁，它确保线程以先到先得的顺序获取锁。这与非公平锁形成对比，非公平锁允许线程以任何顺序获取锁。公平锁对于避免饥饿非常有用，饥饿是指一个线程长时间无法获取锁，因为其他线程不断地抢占它。


#### 操作

`std::condition_variable`：C++ 标准库中的条件变量类，用于线程间的条件等待和通知。
- `wait()`：使当前线程等待条件变量被唤醒，等待时会自动释放持有的互斥锁。
- `notify_one()`：唤醒一个正在等待该条件变量的线程。
- `notify_all()`：唤醒所有正在等待该条件变量的线程。
- `wait_for()`：等待一段时间直到超时，等待时会自动释放持有的互斥锁。
- `wait_until()`：等待直到指定的时间点，等待时会自动释放持有的互斥锁。

#### 示例
以下是一个使用条件变量的示例：

```cpp
#include <iostream>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <queue>
#include <chrono>

std::mutex mtx;
std::condition_variable cv;

std::queue<int> buffer;
const int bufferSize = 10;

void producer(int id) {
    for (int i = 0; i < 300; ++i) {
        std::this_thread::sleep_for(std::chrono::milliseconds(10)); // 模拟生产时间
        {
            std::unique_lock<std::mutex> lock(mtx);
            if (buffer.size() >= bufferSize) {
                std::cout << "Buffer is full. Producer " << id << " is waiting..." << std::endl;
                cv.wait(lock, [] { return buffer.size() < bufferSize; });
            }
            int item = i + (id * 10); // 为不同的生产者生成不同的数据项
            buffer.push(item);
            std::cout << "Producer " << id << " produced: " << item << std::endl;
        }
        cv.notify_all(); // 唤醒等待的消费者
    }
}

void consumer(int id) {
    for (int i = 0; i < 30; ++i) { // 每个消费者消费30次
        std::this_thread::sleep_for(std::chrono::milliseconds(20)); // 模拟消费时间
        {
            std::unique_lock<std::mutex> lock(mtx);
            if (buffer.empty()) {
                std::cout << "Buffer is empty. Consumer " << id << " is waiting..." << std::endl;
                cv.wait(lock, [] { return !buffer.empty(); });
            }
            int item = buffer.front();
            buffer.pop();
            std::cout << "Consumer " << id << " consumed: " << item << std::endl;
        }
        cv.notify_all(); // 唤醒等待的生产者
    }
}

int main() {
    std::thread producers[10];
    std::thread consumers[100];

    for (int i = 0; i < 10; ++i) {
        producers[i] = std::thread(producer, i);
    }

    for (int i = 0; i < 100; ++i) {
        consumers[i] = std::thread(consumer, i);
    }

    for (int i = 0; i < 10; ++i) {
        producers[i].join();
    }

    for (int i = 0; i < 100; ++i) {
        consumers[i].join();
    }

    return 0;
}
```



### 信号量
  
信号量是一种经典的同步机制，用于控制对共享资源的访问数量。它是由计数器和相关的操作集合组成的，用于协调多个线程对共享资源的访问。信号量的基本操作有两个：**P（wait）** 和 **V（signal）**。

**基本操作：**

- **P（wait）**：如果信号量的计数器值大于 0，则将计数器减 1，继续执行；如果计数器值为 0，则当前线程阻塞等待，直到计数器变为大于 0 为止。
    
- **V（signal）**：增加信号量的计数器值，释放一个等待资源的线程。

```c++
class Semaphore
{
  private:
    atomic_int32_t count;
    std::mutex mt_mutex;
    std::condition_variable cond;

  public:
    explicit Semaphore( int count = 0 ) : count( count ) {}
    ~Semaphore( ) = default;
    void signal( )
    {
        std::unique_lock< std::mutex > lock( mt_mutex );
        ++count;
        cond.notify_one( );
        return;
    }
    void signal_all( )
    {
        std::unique_lock< std::mutex > lock( mt_mutex );
        ++count;
        cond.notify_all( );
        return;
    }
    void wait( )
    {
        std::unique_lock< std::mutex > lock( mt_mutex );
        cond.wait( lock, [ = ] { return count > 0; } );
        --count;
        return;
    }
    // void wait_for( const std::chrono::duration< std::chrono::Rep, Period > &rel_time )
    // {
    //     if ( count > 0 )
    //         return;
    //     std::unique_lock< std::mutex > lock( mt_mutex );
    //     cond.wait_for( lock, rel_time, [ = ] { return count > 0; } );
    //     --count;
    //     return;
    // }
};

```

### future机制


# 经典同步问题

[TODO] 本章节没有经过校验

## 生产者消费者问题

生产者消费者问题是经典的同步问题。它模拟了生产者生产产品并将其放在共享缓冲区中，而消费者从共享缓冲区中取出产品进行消费的情况。该问题涉及到两个并发进程之间的协作，因此需要使用同步机制来确保数据的一致性和完整性。

### 问题描述

生产者消费者问题描述如下：

- 存在一个共享的缓冲区，可以存储有限数量的产品。
- 有若干个生产者进程，负责生产产品并将其放入共享缓冲区。
- 有若干个消费者进程，负责从共享缓冲区中取出产品并进行消费。
- 生产者进程只能在缓冲区有足够的空间时才能生产产品，否则必须等待。
- 消费者进程只能在缓冲区中有产品时才能进行消费，否则必须等待。

### C++ 代码示例

```c++
#include <iostream>
#include <queue>
#include <thread>
#include <mutex>
#include <condition_variable>

std::queue<int> buffer;
const int maxBufferSize = 10; // 缓冲区大小
std::mutex mtx;
std::condition_variable bufferEmpty, bufferFull;

void producer()
{
    for (int i = 1; i <= 20; ++i)
    {
        std::unique_lock<std::mutex> lock(mtx);
        bufferFull.wait(lock, []
                        { return buffer.size() < maxBufferSize; }); // 等待直到缓冲区不满

        buffer.push(i);
        std::cout << "Produced: " << i << std::endl;

        lock.unlock();
        bufferEmpty.notify_one();                                    // 唤醒消费者线程
        std::this_thread::sleep_for(std::chrono::milliseconds(200)); // 模拟生产过程
    }
}

void consumer()
{
    for (int i = 1; i <= 20; ++i)
    {
        std::unique_lock<std::mutex> lock(mtx);
        bufferEmpty.wait(lock, []
                         { return !buffer.empty(); }); // 等待直到缓冲区非空

        int item = buffer.front();
        buffer.pop();
        std::cout << "Consumed: " << item << std::endl;

        lock.unlock();
        bufferFull.notify_one();                                     // 唤醒生产者线程
        std::this_thread::sleep_for(std::chrono::milliseconds(300)); // 模拟消费过程
    }
}

int main()
{
    std::thread producerThread(producer);
    std::thread consumerThread(consumer);

    producerThread.join();
    consumerThread.join();

    return 0;
}

```

## 哲学家就餐问题

[维基百科](https://zh.wikipedia.org/wiki/%E5%93%B2%E5%AD%A6%E5%AE%B6%E5%B0%B1%E9%A4%90%E9%97%AE%E9%A2%98)
[leetcode](https://leetcode.cn/problems/the-dining-philosophers/description/)
### 描述
哲学家就餐问题是一个经典的同步问题，它描述了如下场景：

设有五位哲学家围坐在一张圆形餐桌旁，做以下两件事情之一：吃饭，或者思考。吃东西的时候，他们就停止思考，思考的时候也停止吃东西。餐桌上有五碗意大利面，每位哲学家之间各有一只餐叉。因为用一只餐叉很难吃到意大利面，所以假设哲学家必须用两只餐叉吃东西。他们只能使用自己左右手边的那两只餐叉。

这个问题不考虑意大利面有多少，也不考虑哲学家的胃有多大。假设两者都是无限大。

问题在于如何设计一套规则，使得在哲学家们在完全不交谈，也就是无法知道其他人可能在什么时候要吃饭或者思考的情况下，可以在这两种状态下永远交替下去。

### 解题思路

#### 服务生解法

一个简单的解法是引入一个餐厅服务生，哲学家必须经过他的允许才能拿起餐叉。因为服务生知道哪只餐叉正在使用，所以他能够作出判断避免死锁。

为了演示这种解法，假设哲学家依次标号为A至E。如果A和C在吃东西，则有四只餐叉在使用中。B坐在A和C之间，所以两只餐叉都无法使用，而D和E之间有一只空余的餐叉。假设这时D想要吃东西。如果他拿起了第五只餐叉，就有可能发生死锁。相反，如果他征求服务生同意，服务生会让他等待。这样，我们就能保证下次当两把餐叉空余出来时，一定有一位哲学家可以成功的得到一对餐叉，从而避免了死锁。
```c++
#include <atomic>
#include <functional>
#include <condition_variable>

using namespace std;

class Waiter
{
private:
    std::mutex mtx;
    std::condition_variable m_cv;
    bool forks[5] = {false, false, false, false, false};

public:
    Waiter(/* args */) {}

    ~Waiter() {}

    void request(int philosopher)
    {
        unique_lock<mutex> lock(mtx);

        auto func = [this, philosopher]()
        {
            return forks[philosopher] == false && forks[(philosopher + 1) % 5] == false;
        };

        m_cv.wait(lock, func);

        forks[philosopher] = true;
        forks[(philosopher + 1) % 5] = true;
    }

    void release(int philosopher)
    {
        {
            unique_lock<mutex> lock(mtx);
            forks[philosopher] = false;
            forks[(philosopher + 1) % 5] = false;
        }
        m_cv.notify_all();
    }
};

class DiningPhilosophers
{
    Waiter t;

public:
    DiningPhilosophers() : t()
    {
    }

    void wantsToEat(int philosopher,
                    function<void()> pickLeftFork,
                    function<void()> pickRightFork,
                    function<void()> eat,
                    function<void()> putLeftFork,
                    function<void()> putRightFork)
    {
        t.request(philosopher);
        pickLeftFork();
        pickRightFork();
        eat();
        putLeftFork();
        putRightFork();
        t.release(philosopher);
    }
};


```
#### 资源分级解法

另一个简单的解法是为资源（这里是餐叉）分配一个[偏序](https://zh.wikipedia.org/wiki/%E5%81%8F%E5%BA%8F "偏序")或者分级的关系，并约定所有资源都按照这种顺序获取，按相反顺序释放，而且保证不会有两个无关资源同时被同一项工作所需要。在哲学家就餐问题中，资源（餐叉）按照某种规则编号为1至5，每一个工作单元（哲学家）总是先拿起左右两边编号较低的餐叉，再拿编号较高的。用完餐叉后，他总是先放下编号较高的餐叉，再放下编号较低的。在这种情况下，当四位哲学家同时拿起他们手边编号较低的餐叉时，只有编号最高的餐叉留在桌上，从而第五位哲学家就不能使用任何一只餐叉了。而且，只有一位哲学家能使用最高编号的餐叉，所以他能使用两只餐叉用餐。当他吃完后，他会先放下编号最高的餐叉，再放下编号较低的餐叉，从而让另一位哲学家拿起后边的这只开始吃东西。

尽管资源分级能避免死锁，但这种策略并不总是实用的，特别是当所需资源的列表并不是事先知道的时候。例如，假设一个工作单元拿着资源3和5，并决定需要资源2，则必须先要释放5，之后释放3，才能得到2，之后必须重新按顺序获取3和5。对需要访问大量数据库记录的计算机程序来说，如果需要先释放高编号的记录才能访问新的记录，那么运行效率就不会高，因此这种方法在这里并不实用。

**本质上还是破坏循坏依赖，实际上不需要对数字进行分级，如果仅仅是解决哲学家问题的话，只需要让某个人的拿起叉子的顺序与其他所有人都不一样即可。**
```c++
#include <atomic>
#include <functional>

using namespace std;

class DiningPhilosophers
{
    std::mutex m[5];

public:
    DiningPhilosophers()
    {
    }

    void wantsToEat(int philosopher,
                    function<void()> pickLeftFork,
                    function<void()> pickRightFork,
                    function<void()> eat,
                    function<void()> putLeftFork,
                    function<void()> putRightFork)
    {
        int lhs = philosopher;
        int rhs = (philosopher + 1) % 5;
        if(lhs > rhs) {
            swap(lhs, rhs);
        }

        m[lhs].lock();
        m[rhs].lock();

        if(rhs == lhs + 1)
        {
            pickLeftFork();
            pickRightFork();

            eat();
            
            putRightFork();
            putLeftFork();
        }
        else
        {
            pickRightFork();
            pickLeftFork();

            eat();

            putLeftFork();
            putRightFork();
        }

        m[rhs].unlock();
        m[lhs].unlock();
    }
};
```

#### 奇偶解法
```c++
#include <atomic>
#include <functional>

using namespace std;

class DiningPhilosophers
{
    std::mutex m[5];

public:
    DiningPhilosophers()
    {
    }

    void wantsToEat(int philosopher,
                    function<void()> pickLeftFork,
                    function<void()> pickRightFork,
                    function<void()> eat,
                    function<void()> putLeftFork,
                    function<void()> putRightFork)
    {

        if (philosopher % 2 == 0)
        {
            m[philosopher].lock();
            m[(philosopher + 1) % 5].lock();
            pickLeftFork();
            pickRightFork();
        }
        else
        {
            m[(philosopher + 1) % 5].lock();
            m[philosopher].lock();

            pickRightFork();
            pickLeftFork();
        }

        eat();

        if (philosopher % 2 == 0)
        {
            putRightFork();
            putLeftFork();
            m[(philosopher + 1) % 5].unlock();
            m[philosopher].unlock();
        }
        else
        {
            putLeftFork();
            putRightFork();
            m[philosopher].unlock();
            m[(philosopher + 1) % 5].unlock();
        }
    }
};
```

#### 减少同时抢占数量
最多允许有四个哲学家线程去抢叉子。
有公平调度的问题。
```c++
#include <atomic>
#include <functional>
#include <condition_variable>

using namespace std;

class DiningPhilosophers
{
    std::mutex m[5];
    int count;
    std::condition_variable cv;
    std::mutex cv_mtx;

public:
    DiningPhilosophers() : count(4)
    {
    }

    void wantsToEat(int philosopher,
                    function<void()> pickLeftFork,
                    function<void()> pickRightFork,
                    function<void()> eat,
                    function<void()> putLeftFork,
                    function<void()> putRightFork)
    {
        int left = philosopher;
        int right = (philosopher + 1) % 5;
        {
            std::unique_lock<std::mutex> lk(cv_mtx);
            cv.wait(lk, [this]
                    { return count > 0; });
            count--;
        }

        m[left].lock();
        m[right].lock();
        pickLeftFork();
        pickRightFork();
        eat();
        putLeftFork();
        putRightFork();
        m[left].unlock();
        m[right].unlock();

        {
            std::unique_lock<std::mutex> lk(cv_mtx);
            count++;
        }
        cv.notify_one();
    }
};
```


#### 钱迪/米斯拉解法


[[分布式系统/哲学家问题-钱迪-米斯拉解法\|哲学家问题-钱迪-米斯拉解法]]

1984年，[曼尼·钱迪](https://zh.wikipedia.org/w/index.php?title=%E6%9B%BC%E5%B0%BC%C2%B7%E9%92%B1%E8%BF%AA&action=edit&redlink=1)和[贾亚达夫·米斯拉](https://zh.wikipedia.org/w/index.php?title=%E8%B4%BE%E4%BA%9A%E8%BE%BE%E5%A4%AB%C2%B7%E7%B1%B3%E6%96%AF%E6%8B%89&action=edit&redlink=1)提出了哲学家就餐问题的另一个解法，允许任意的用户（编号$P_1, P_2, ..., P_n$）争用任意数量的资源。与资源分级解法不同的是，这里编号可以是任意的。

- 对每一对竞争一个资源的哲学家，新拿一个餐叉，给编号较低的哲学家。每只餐叉都是“干净的”或者“脏的”。最初，所有的餐叉都是脏的。
- 当一位哲学家要使用资源（也就是要吃东西）时，他必须从与他竞争的邻居那里得到。对每只他当前没有的餐叉，他都发送一个请求。
- 当拥有餐叉的哲学家收到请求时，如果餐叉是干净的，那么他继续留着，否则就擦干净并交出餐叉。
- 当某个哲学家吃东西后，他的餐叉就变脏了。如果另一个哲学家之前请求过其中的餐叉，那他就擦干净并交出餐叉。



### C++代码样例

#### 错误样例1
```c++
// 错误样例：
#include <iostream>
#include <thread>
#include <mutex>
#include <condition_variable>

const int NUM_PHILOSOPHERS = 5;

std::mutex forks[NUM_PHILOSOPHERS];

void philosopher(int philosopher_id)
{
    while (true)
    {
        int left_fork = philosopher_id;
        int right_fork = (philosopher_id + 1) % NUM_PHILOSOPHERS;

		// 有可能造成死锁, 也有可能饿死某些哲学家
        std::unique_lock<std::mutex> left_lock(forks[left_fork]);
        std::unique_lock<std::mutex> right_lock(forks[right_fork]);

        // 模拟哲学家进餐
        std::cout << "Philosopher " << philosopher_id << " is eating." << std::endl;

        // 释放叉子
        right_lock.unlock();
        left_lock.unlock();
            
        // 模拟哲学家思考
        std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    }
}

int main()
{
    std::thread philosophers[NUM_PHILOSOPHERS];

    // 创建哲学家线程
    for (int i = 0; i < NUM_PHILOSOPHERS; ++i)
    {
        philosophers[i] = std::thread(philosopher, i);
    }

    // 等待所有哲学家线程完成
    for (int i = 0; i < NUM_PHILOSOPHERS; ++i)
    {
        philosophers[i].join();
    }

    return 0;
}

```

#### 错误样例2

```c++
#include <iostream>
#include <thread>
#include <mutex>
#include <condition_variable>

using namespace std;

const int num_philosophers = 5;
mutex forks[num_philosophers];
condition_variable cv[num_philosophers];
bool using_forks[num_philosophers];

void philosopher(int id)
{
    while (true)
    {
        // 思考
        cout << "Philosopher " << id << " is thinking." << endl;

        // 仍然有可能出现死锁问题
        // 仍然会有哲学家饿死的问题

        // 拿起左边叉子
        unique_lock<mutex> lock_left(forks[id]);
        cv[id].wait(lock_left, [&]
                    { return !using_forks[id]; });
        using_forks[id] = true;

        // 拿起右边叉子
        unique_lock<mutex> lock_right(forks[(id + 1) % num_philosophers]);
        using_forks[(id + 1) % num_philosophers] = true;

        // 吃面
        cout << "Philosopher " << id << " is eating." << endl;
        this_thread::sleep_for(chrono::milliseconds(500));

        // 放下右边叉子
        using_forks[(id + 1) % num_philosophers] = false;
        lock_right.unlock();
        cv[(id + 1) % num_philosophers].notify_one();

        // 放下左边叉子
        using_forks[id] = false;
        lock_left.unlock();
        cv[id].notify_one();
    }
}

int main()
{
    thread philosophers[num_philosophers];

    for (int i = 0; i < num_philosophers; i++)
    {
        philosophers[i] = thread(philosopher, i);
    }

    for (int i = 0; i < num_philosophers; i++)
    {
        philosophers[i].join();
    }

    return 0;
}
```



## 读者写者问题

读者写者问题是经典同步问题之一，它描述了一个共享数据结构（如数据库）由多个读者和一个写入器共享的情况。每个读者都可以同时访问该数据结构，而写入器在写入数据时必须独占地访问该数据结构。因此，我们需要某种同步机制来协调读者和写入器的访问，以确保数据的一致性和完整性。

### 基本模型

读者写者问题的基本模型如下：

* **读者线程**：读者线程并发地访问共享数据结构，但不会修改它。
* **写入者线程**：写入者线程并发地访问共享数据结构，并修改它。
* **共享数据结构**：共享数据结构可以被多个读者同时访问，但只能被一个写入者独占地访问。

### 解决方案

读者写者问题有几种不同的解决方案，其中最常见的一种是使用读写锁。读写锁是一种锁机制，它允许多个读者同时访问共享数据结构，但只能允许一个写入者独占地访问共享数据结构。

## 熟睡的理发师问题

在理发店里，有一个理发师和N个椅子，理发师在等待第一个顾客时会睡觉。顾客到来后，理发师会睡醒，给顾客理发。理发完成后，顾客离开，理发师继续睡觉。这个理发师问题是一个经典的同步问题，因为它涉及到多个进程之间的同步。

### 问题描述

理发店有一个理发师和N个椅子。理发师在等待第一个顾客时会睡觉。顾客到来后，理发师会睡醒，给顾客理发。理发完成后，顾客离开，理发师继续睡觉。

### 解决方案

```c++
#include <iostream>
#include <condition_variable>
#include <mutex>
#include <thread>

using namespace std;

// 理发店类
class Barbershop {
public:
    Barbershop(int num_chairs) : num_chairs(num_chairs), done(false) {}

    // 理发师线程函数
    void barber() {
        while (!done) {
            // 加锁
            unique_lock<mutex> lock(m);

            // 等待顾客到来
            cv.wait(lock, [this] { return !customers.empty(); });

            // 获取一位顾客
            Customer customer = customers.front();
            customers.pop();

            // 给顾客理发
            cout << "理发师给顾客" << customer << "理发" << endl;

            // 解锁
            lock.unlock();

            // 给顾客理发需要花费一定的时间
            this_thread::sleep_for(chrono::milliseconds(1000));
        }
    }

    // 顾客线程函数
    void customer(int id) {
        // 加锁
        unique_lock<mutex> lock(m);

        // 如果椅子满了，则等待
        while (customers.size() == num_chairs) {
            cv.wait(lock);
        }

        // 坐下等待理发
        customers.push(id);

        // 唤醒理发师
        cv.notify_one();

        // 解锁
        lock.unlock();
    }

    // 理发结束
    void finish() {
        done = true;
        cv.notify_all();
    }

private:
    int num_chairs;
    queue<int> customers;
    mutex m;
    condition_variable cv;
    bool done;
};

int main() {
    // 创建一个理发店，有3把椅子
    Barbershop barbershop(3);

    // 创建一个理发师线程
    thread barber_thread(&Barbershop::barber, &barbershop);

    // 创建10个顾客线程
    vector<thread> customer_threads;
    for (int i = 0; i < 10; i++) {
        customer_threads.push_back(thread(&Barbershop::customer, &barbershop, i));
    }

    // 等待理发师和顾客线程结束
    barber_thread.join();
    for (auto& t : customer_threads) {
        t.join();
    }

    // 理发结束
    barbershop.finish();

    return 0;
}
```


## 三个烟鬼问题
### 问题描述
三个烟鬼在一个房间里，每个烟鬼有无限根烟，他们想要轮流吸烟，但是他们只有一盒火柴，每次只有一根火柴可用，并且火柴只能使用一次。

三个烟鬼商定，他们每个人轮流吸一支烟，然后顺时针传递火柴，直到所有人都吸完烟。问题是，他们该如何防止有人作弊，偷偷多吸一根烟？

### 解决方案
这个问题可以通过使用令牌来解决。令牌可以是任何物体，比如硬币、钥匙或打火机。在开始吸烟之前，他们将令牌传递给下一位烟鬼。当一个烟鬼吸完烟后，他必须将令牌传给下一位烟鬼。如果有人试图作弊，他将没有令牌，会被发现。

### C++代码示例
```c++
#include <iostream>
#include <thread>
#include <mutex>

using namespace std;

mutex m;

void smoker(int id) {
  while (true) {
    unique_lock<mutex> lock(m);
    // Wait for my turn
    while (/* condition */) {
      cv.wait(lock);
    }
    // Smoke
    cout << "Smoker " << id << " is smoking" << endl;
    // Pass the token
    /* code */
    // Signal the next smoker
    cv.notify_one();
  }
}

int main() {
  thread t1(smoker, 1);
  thread t2(smoker, 2);
  thread t3(smoker, 3);

  t1.join();
  t2.join();
  t3.join();

  return 0;
}
```

# C++多线程高级编程

## 线程池

```c++
#pragma once

#include <atomic>
#include <functional>
#include <future>
#include <mutex>
#include <queue>
#include <thread>
#include <vector>

namespace MyUtils
{
using namespace std;
namespace Thread
{

//线程池,可以提交变参函数或拉姆达表达式的匿名函数执行,可以获取执行返回值
//不直接支持类成员函数, 支持类静态成员函数或全局函数,Opteron()函数等
class ThreadPool
{
  private:
    //线程池最大容量,应尽量设小一点
    const unsigned int THREADPOOL_MAX_NUM;
    using Task = function< void( ) >; //定义类型
    vector< thread > _pool;           //线程池
    queue< Task > _tasks;             //任务队列
    mutex _lock;                      //同步
    condition_variable _task_cv;      //条件阻塞
    atomic< bool > _run{ true };      //线程池是否执行
    atomic< int > _idlThrNum{ 0 };    //空闲线程数量

  public:
    ThreadPool( ) = delete;
    ThreadPool( const ThreadPool &other ) = delete;
    ThreadPool &operator=( const ThreadPool &other ) = delete;
    explicit ThreadPool( unsigned short max_size = 4 )
        : THREADPOOL_MAX_NUM( max_size )
    {
        addThread( );
    }
    ~ThreadPool( ) { waitAll( ); }

  public:
    // 提交一个任务
    // 调用.get()获取返回值会等待任务执行完,获取返回值
    // 有两种方法可以实现调用类成员，
    // 一种是使用   bind： .commit(std::bind(&Dog::sayHello, &dog));
    // 一种是用   mem_fn： .commit(std::mem_fn(&Dog::sayHello), this)
    template < class F, class... Args >
    auto commit( F &&f, Args &&...args ) -> future< decltype( f( args... ) ) >
    {
        if ( !_run ) // stoped ??
            throw runtime_error( "ThreadPool is stopped." );

        using RetType = decltype( f(
            args... ) ); // typename std::result_of<F(Args...)>::type, 函数 f
                         // 的返回值类型
        auto task = make_shared< packaged_task< RetType( ) > >(
            bind( forward< F >( f ),
                  forward< Args >( args )... ) ); // 把函数入口及参数,打包(绑定)
        future< RetType > future = task->get_future( );
        { // 添加任务到队列
            lock_guard< mutex > lock{
                _lock }; //对当前块的语句加锁  lock_guard 是 mutex 的 stack
                         //封装类，构造的时候 lock()，析构的时候 unlock()
            _tasks.emplace( [ task ]( ) { // push(Task{...}) 放到队列后面
                ( *task )( );
            } );
        }
#ifdef THREADPOOL_AUTO_GROW
        if ( _idlThrNum < 1 && _pool.size( ) < THREADPOOL_MAX_NUM )
            addThread( 1 );
#endif                          // !THREADPOOL_AUTO_GROW
        _task_cv.notify_one( ); // 唤醒一个线程执行

        return future;
    }

    //空闲线程数量
    int idlCount( ) { return _idlThrNum; }
    //线程数量
    int thrCount( ) { return _pool.size( ); }

    /**
     * @brief waitAll 等待所有线程执行完。同时也意味着该线程池寿终正寝。
    */
    inline bool waitAll( )
    {
        _run = false;

        _task_cv.notify_all( ); // 唤醒所有线程执行
        for ( thread &thread : _pool )
        {
            // thread.detach(); // 让线程“自生自灭”
            if ( thread.joinable( ) )
                thread.join( ); // 等待任务结束， 前提：线程一定会执行完
        }
        return true;
    }

#ifndef THREADPOOL_AUTO_GROW
  private:
#else
  public:
#endif // !THREADPOOL_AUTO_GROW
    //添加指定数量的线程
    void addThread( )
    {
        while ( _pool.size( ) < THREADPOOL_MAX_NUM )
        { //增加线程数量,但不超过 预定义数量 THREADPOOL_MAX_NUM
            _pool.emplace_back( [ this ] { //工作线程函数
                while ( _run )
                {
                    Task task; // 获取一个待执行的 task
                    {
                        // unique_lock 相比 lock_guard 的好处是：可以随时
                        // unlock() 和 lock()
                        unique_lock< mutex > lock{ _lock };
                        _task_cv.wait( lock, [ this ] {
                            return !_run || !_tasks.empty( );
                        } ); // wait 直到有 task
                        if ( !_run && _tasks.empty( ) )
                            return;
                        task = move(
                            _tasks.front( ) ); // 按先进先出从队列取一个 task
                        _tasks.pop( );
                    }
                    _idlThrNum--;
                    task( ); //执行任务
                    _idlThrNum++;
                }
            } );
            _idlThrNum++;
        }
    }
};
} // namespace Thread

} // namespace MyUtils

```

## 并发容器

略


# C++无锁编程

## 无锁编程

无锁编程是一种并发编程的范式，旨在解决多线程环境下的竞态条件，而无需使用传统的锁机制（如互斥锁、读写锁等）。其主要目标是避免锁的使用，从而提高并发程序的性能和可伸缩性，并减少由于锁竞争而带来的开销和潜在的死锁风险。

1. **避免锁的竞争**：传统锁机制可能会引入锁的竞争，多个线程争抢同一把锁，降低了并发程序的性能。无锁编程的目标是避免这种竞争。
    
2. **无等待**：无锁编程力求避免在多线程间出现等待（包括忙等待和阻塞等待）。在无锁算法中，操作不会阻塞线程的执行，也不会因为资源的繁忙而持续忙等。
    
3. **数据结构设计**：通过精心设计数据结构，使用原子操作和类似 CAS（Compare-And-Swap）的原子指令来实现并发安全。比如，使用原子操作来保证对共享数据的原子性操作。
    
4. **提高性能和伸缩性**：无锁编程通常能够提高并发程序的性能和可伸缩性，因为它避免了锁带来的开销和竞争。
    
5. **降低复杂性和风险**：使用锁可能引入复杂性和潜在的死锁风险。无锁编程通常更加简单明了，并且减少了因为锁引入的一些风险。
    
6. **适用场景**：无锁编程并非适用于所有场景，它更适合于高并发和对性能要求较高的场景。在某些情况下，锁可能是更简单、更安全的选择。

## 原子操作

### 概念
1. **不可分割性**：原子操作是不可被中断或分割的，要么全部执行成功，要么不执行，不会出现中间状态。
    
2. **线程安全性**：多个线程同时进行原子操作不会破坏数据的一致性，不需要额外的同步机制（如锁）来保护。
    
3. **硬件级支持**：原子操作通常依赖于硬件的原子性指令，比如 CPU 的 CAS（Compare-And-Swap）指令。
### 特性 
原子操作具有以下几个重要的特性：

1. 原子性（Atomicity）

原子操作是不可中断的，要么全部执行成功，要么完全不执行。在多线程环境下，即使有多个线程同时对共享资源进行原子操作，也不会出现数据被破坏或处于不一致状态的情况。这种特性确保了多线程操作时的数据一致性。

 2. 可见性（Visibility）

原子操作对其他线程的操作具有可见性。一个线程对共享数据进行了原子操作后，其他线程能够立即看到这个变化，而不需要额外的同步机制。这确保了在多线程环境中对共享资源的修改对其他线程是可见的。

 3. 无锁机制（Lock-Free）

原子操作通常是无锁的，在执行期间不需要使用传统的锁机制（如互斥锁、读写锁等）。这种特性使得原子操作在高并发和高性能要求的场景下具有优势，因为无锁机制减少了线程间的竞争和阻塞。

4. 原子性指令的硬件支持

在硬件级别上，原子操作通常依赖于特定的原子性指令，比如 CAS（Compare-And-Swap）指令。这些指令能够确保在执行原子操作时不被中断，提供了原子操作的基础。

5. 并发安全性

原子操作提供了并发编程中对共享资源进行安全操作的手段，通过保证对数据的原子操作，避免了数据竞争、死锁和其他并发问题。

### 原子操作的类型：

1. **原子加载（Load）**：从内存中读取一个值并返回。在 C++ 中，可以使用 `std::atomic<T>::load()` 来进行原子加载操作。
    
2. **原子存储（Store）**：将一个值存储到内存中。在 C++ 中，可以使用 `std::atomic<T>::store()` 来进行原子存储操作。
    
3. **原子交换（Exchange）**：将一个值存储到内存中，并返回原先的值。在 C++ 中，可以使用 `std::atomic<T>::exchange()` 来进行原子交换操作。
    
4. **原子比较和交换（Compare-And-Swap，CAS）**：比较某个内存位置的值与预期值，如果相等，则将该位置的值替换为新值。在 C++ 中，可以使用 `std::atomic<T>::compare_exchange_weak()` 或 `std::atomic<T>::compare_exchange_strong()` 来进行 CAS 操作。原子的比较 `*this`  和 `expect的值`，若它们逐位相等，则以 `desired` 替换前者（进行读修改写操作）。否则，将 `*this` 中的实际值加载进 `expected` （进行加载操作）。
    
5. **原子增减操作**：对一个数进行原子的加减操作。在 C++ 中，可以使用 `std::atomic<T>::fetch_add()` 和 `std::atomic<T>::fetch_sub()` 来进行原子的增减操作。

## 自选锁
```c++
#include <iostream>
#include <atomic>
#include <thread>

class SpinLock {
private:
    std::atomic_flag flag = ATOMIC_FLAG_INIT;

public:
    SpinLock() = default;

    ~SpinLock() {
        unlock();
    }

    void lock() {
        while (flag.test_and_set(std::memory_order_acquire)) {
            // 等待锁的释放
        }
    }

    void unlock() {
        flag.clear(std::memory_order_release); // 释放锁
    }
};

void someFunction() {
    SpinLock spinLock;
    spinLock.lock(); // 获取锁
    // 临界区代码
    std::cout << "Locked!" << std::endl;
    // 不需要显式调用 unlock，因为在 spinLock 的析构函数中会自动释放锁
}

int main() {
    std::thread t1(someFunction);
    std::thread t2(someFunction);

    t1.join();
    t2.join();

    return 0;
}

```

## 无锁栈

```c++
#pragma once

#include <atomic>
#include <memory>

template <typename T>
class LockFreeStack
{
private:
    struct Node
    {
        std::shared_ptr<T> data;
        Node *next;

        Node(T const &data) : data(std::make_shared<T>(data)), next(nullptr) {}
        Node() : next(nullptr) {}
        virtual ~Node() {}
    };

    std::atomic<Node *> m_head;
    std::atomic<Node *> m_to_be_deleted;

    std::atomic<unsigned> m_threads_in_pop;

public:
    LockFreeStack() : m_head(nullptr) {}

    virtual ~LockFreeStack()
    {
        while (!empty())
        {
            pop();
        }
    }

    void push(T const &data)
    {
        Node *newNode = new Node(data);
        newNode->next = m_head.load();
        while (!m_head.compare_exchange_weak(newNode->next, newNode))
            ;
    }

    std::shared_ptr<T> pop()
    {
        ++m_threads_in_pop;
        Node *oldHead = m_head.load();
        while (oldHead && !m_head.compare_exchange_weak(oldHead, oldHead->next))
            ;

        // 执行至此时，不可能有多个线程同时对 oldHead 持有引用

        auto res = oldHead ? oldHead->data : std::shared_ptr<T>();

        try_reclaim(oldHead);

        return res;
    }

    // unsafe, 但是不会造成 try_reclaim 的不安全，是 try_reclaim 造成了 top() 的不安全
    std::shared_ptr<T> top()
    {
        Node *oldHead = m_head.load();
        return oldHead ? oldHead->data : std::shared_ptr<T>();
    }

    bool empty()
    {
        // safe
        return m_head.load() == nullptr;
    }

private:
    void try_reclaim(Node *oldHead)
    {
        if (m_threads_in_pop == 1)
        {
            // 最多只有一个线程执行到该分支，不可能有多个线程会同时执行该分支

            // 这里所有的执行操作之所以是安全的是因为，凡是在这里的节点
            // 都是被之前的进入pop的线程加入到待删除队列的，
            // 而此时线程为1，说明之前进入pop的线程已经执行完了
            // 即使再有其他的线程进入pop,也不可能持有对已经加入待删除队列的节点的引用（待删除队列的头节点除外）

            Node *nodes_to_delete = m_to_be_deleted.exchange(nullptr);

            // 头节点之后的节点都是可以被安全删除的
            if (nodes_to_delete)
            {
                Node *safe_to_delete = nodes_to_delete->next;

                // nodes_to_delete->next 的读/写引用，只有当前线程会做，因此是不会产生冲突
                // 但是 nodes_to_delete->data 的读引用，有可能其他线程也会做，因此无法删除该节点
                nodes_to_delete->next = nullptr;
                delete_nodes(safe_to_delete);
            }

            if (1 == m_threads_in_pop)
            {
                // 再次判断是否只有一个线程在执行pop
                // 如果依然只有当前线程，那么只有当前线程持有对nodes_to_delete指向的空间的引用
                // 那就直接删除所有已经pending的节点
                // 由于判断语句的存在，这里的删除操作是绝对安全的
                delete nodes_to_delete;
                nodes_to_delete = nullptr;
            }
            else
            {
                // 当前不是当前线程正在执行pop的唯一线程
                // 那么就有可能多个线程持有对nodes_to_delete指向的空间的引用

                if (nodes_to_delete)
                {
                    // 把另一个待删除队列的头节点添加到当前待删除队列的最后面
                    nodes_to_delete->next = m_to_be_deleted;
                    while (!m_to_be_deleted.compare_exchange_weak(nodes_to_delete->next, nodes_to_delete))
                        ;
                }
            }

            // 这里删除 oldHead 是绝对安全的，是因为前面已经分析过了
            // 可能访问 oldHead 的线程只有当前线程之前进入pop的线程，
            // 但是这些线程已经执行完毕了，因此这里可以安全的删除 oldHead
            delete oldHead;

            --m_threads_in_pop;
        }
        else
        {
            oldHead->next = m_to_be_deleted;
            while (!m_to_be_deleted.compare_exchange_weak(oldHead->next, oldHead))
                ;
            --m_threads_in_pop;
        }
    }

    static void delete_nodes(Node *nodes)
    {
        while (nodes)
        {
            Node *next = nodes->next;
            delete nodes;
            nodes = next;
        }
    }
};

```

## 内存屏障
- [Memory Barriers: a Hardware View for Software Hackers]
-  riscv体系结构: 编程与实践

### 内存屏障的概念和类型

内存屏障是一种指令，它可以防止指令在内存屏障之前和之后重新排序。与没有内存屏障的情况相比，内存屏障具有以下优点：

* 正确性：内存屏障可以防止指令在内存屏障之前和之后重新排序，因此可以保证程序的正确性。
* 一致性：内存屏障可以防止指令在内存屏障之前和之后重新排序，因此可以保证程序的一致性。
* 隔离性：内存屏障可以防止指令在内存屏障之前和之后重新排序，因此可以保证程序的隔离性。

### 内存屏障的实现

内存屏障可以通过以下方式实现：

* 硬件支持：一些硬件平台支持内存屏障，例如x86平台支持内存屏障指令。
* 软件模拟：在没有硬件支持的情况下，内存屏障可以通过软件模拟实现。

### 内存屏障的用法

内存屏障可以在以下情况下使用：

* 在多线程编程中，内存屏障可以防止指令在不同的线程之间重新排序。
* 在多处理器编程中，内存屏障可以防止指令在不同的处理器之间重新排序。
* 在设备驱动程序编程中，内存屏障可以防止指令在设备驱动程序和设备之间重新排序。

## 无锁编程实践

### 无锁编程的最佳实践和陷阱

无锁编程是一种复杂的编程技术，因此在实践中需要注意以下最佳实践和陷阱：

* 最佳实践：
    * 使用无锁数据结构。
    * 使用无锁算法。
    * 使用乐观锁。
    * 使用内存屏障。
* 陷阱：
    * 死锁：无锁编程可能会导致死锁，因此需要小心避免死锁。
    * 饥饿：无锁编程可能会导致饥饿，因此需要小心避免饥饿。
    * 性能下降：无锁编程可能会导致性能下降，因此需要小心避免性能下降。

### 无锁编程的常见问题和解决方案

无锁编程中常见的



# 多线程的常见问题

## 竞态条件

竞态条件发生在两个或多个线程同时访问共享数据时。例如，如果两个线程都尝试更新同一个变量，那么最终的结果可能会取决于哪个线程先获得对变量的访问权。

## 死锁

多线程的一个常见问题是死锁。死锁发生在两个或多个线程等待彼此释放锁时。例如，如果一个线程持有资源A的锁，另一个线程持有资源B的锁，并且这两个线程都尝试获取对方持有的锁，那么就会发生死锁。

**死锁发生的条件：**
1. **互斥**：一个资源在同一时间只能被一个线程使用。
2. **请求与保持**：一个线程在等待一个资源时，不能释放它持有的其他资源。
3. **不可抢占**：一个线程已获得的资源，在末使用完之前，不能强行剥夺。
4. **循环等待**：存在一组线程，每个线程都等待另一个线程释放它持有的资源。

```c++
#include <iostream>
#include <thread>
#include <mutex>

std::mutex mutex1, mutex2;

void threadFunction1() {
    std::lock_guard<std::mutex> lock1(mutex1);
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));

	// try to acquire the second mutex but cannot acquire it
	// because the mutex has been acquired by the second thread
    std::lock_guard<std::mutex> lock2(mutex2);
    std::cout << "Thread 1 acquired both locks" << std::endl;
}

void threadFunction2() {
    std::lock_guard<std::mutex> lock2(mutex2);
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
	
	// try to acquire the first mutex but cannot acquire it
	// because the mutex has been acquired by the first thread
    std::lock_guard<std::mutex> lock1(mutex1);
    std::cout << "Thread 2 acquired both locks" << std::endl;
}

int main() {
    std::thread t1(threadFunction1);
    std::thread t2(threadFunction2);

    t1.join();
    t2.join();

    return 0;
}

```

编译：
```sh
g++ -std=c++11 -pthread deadlock.cpp -o deadlock
```


## 饥饿

饥饿发生在某个线程长时间无法获得CPU时间时。例如，如果一个线程被其他线程频繁地抢占，那么这个线程可能会长时间无法执行。

```c++
#include <iostream>
#include <thread>
#include <mutex>
#include <chrono>

std::mutex mtx;
bool flag = false;

void worker(int t) {
    while (true) {
        std::unique_lock<std::mutex> lock(mtx);
        while (!flag) {
            // 等待条件满足
            lock.unlock();
            std::this_thread::sleep_for(std::chrono::milliseconds(t)); // 休眠一段时间
            lock.lock();
        }
        std::cout << "Thread " << std::this_thread::get_id() << " is working..." << std::endl;
        flag = false;
        lock.unlock();
        std::this_thread::sleep_for(std::chrono::milliseconds(t)); // 模拟工作
    }
}

void scheduler() {
    while (true) {
        std::unique_lock<std::mutex> lock(mtx);
        flag = true;
        std::cout << "Scheduler: Flag set to true." << std::endl;
        lock.unlock();
        std::this_thread::sleep_for(std::chrono::milliseconds(500)); // 模拟较长的工作
    }
}

int main() {
    std::thread t1(worker, 1000);
    std::thread t2(worker, 1);
    std::thread t3(scheduler);

    t1.join();
    t2.join();
    t3.join();

    return 0;
}

```

## 公平调度问题


## 解决多线程问题的方法

* 使用锁来保护共享数据。
* 使用信号量来协调线程之间的访问。
* 使用优先级来确保重要线程获得更多的CPU时间。
* 使用死锁检测和预防机制来避免死锁。
* 使用线程池来管理线程，防止创建过多线程。


# C++多线程调试

- **检测死锁**
- **检测竞态条件**
- **检测数据竞争**



# C++多线程最佳实践

## 经验总结

多线程编程是一个极其复杂的技术，这是分布式系统/并发编程技术的基础。如何设计、实现多线程是个很吃经验的工作。在这里，我浅薄地谈一下多线程编程经验。


- **避免常见的错误**
- **编写可移植的多线程代码**
- **编写可伸缩的多线程代码**
- **编写可靠的多线程代码**

# 参考资料
- c++ councurrency in action
- riscv体系结构: 编程与实践
- [A complete guide to Linux process schedulin](https://trepo.tuni.fi/bitstream/handle/10024/96864/GRADU-1428493916.pdf)