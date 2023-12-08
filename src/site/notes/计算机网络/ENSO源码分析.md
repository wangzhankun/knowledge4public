---
{"dg-publish":true,"date":"2023-12-08","time":"19:41","progress":"进行中","tags":["网络"],"permalink":"/计算机网络/ENSO源码分析/","dgPassFrontmatter":true}
---




论文参见 [[计算机网络/ENSO：A Streaming Interface for NIC-Application Communication——2023\|ENSO：A Streaming Interface for NIC-Application Communication——2023]]
# ENSO源码分析

# 类简介

|类名 |说明 |
|---|---|
|QueueRegs |无方法，只包含变量，全是public，是NotificationBufPair::uio_mmap_bar2_addr映射的内存的一部分。 volatile struct QueueRegs* enso_pipe_regs =      (struct QueueRegs*)((uint8_t*)uio_mmap_bar2_addr +                          enso_pipe_id * kMemorySpacePerQueue);uio_mmap_bar2_addr是在notification_buf_init()函数中通过mmap映射进来的。映射的PCIE设备的内存。 |
|NotificationBufPair |记录了rxpipe、txpipe等的关键信息，如rx_head\rx_tail\tx_head\tx_tail等信息。由notification_buf_init()负责初始化和分配资源，notification_buf_free()负责释放资源。 |
|RxEnsoPipeInternal | |
|Device | |
|Device::TxPendingRequest | |
|RxPipe |负责管理rx_pipe缓冲区 |
|RxPipe::MessageBatch |声明和定义在RxPipe类中。表示一批消息，是一个模板类，在模板的实例化中，是使用PktIterator和PeekPktIterator进行的实例化。 |
|TxPipe |负责管理tx_pipe缓冲区 |
|RxTxPipe |负责管理rx_tx_pipe缓冲区，该缓冲区既是txpipe也是rxpipe，适用于需要本地修改已接受到的报文然后发送的情况。 |
|MessageIteratorBase |PktIterator和PeekPktIterator的基类，核心在于定义了`T& operator++()`函数。这也是一个模板类，在实例化时，是使用PktIterator和PeekPktIterator进行的实例化。 |
|PktIerator |继承至MessageIteratorBase<PktIterator> |
|PeekPktIterator |继承至MessageIteratorBase<PeekPktIterator> |
|Queue | |
|Queue::Element | |
|QueueProducer | |
|QueueConsumer | |
|SocketInternal | |

# 迭代器设计

在迭代器的设计中，主要有四个类：

|MessageBatch |声明和定义在RxPipe类中。表示一批消息，是一个模板类，在模板的实例化中，是使用PktIterator和PeekPktIterator进行的实例化。 |
|---|---|
|MessageIteratorBase |PktIterator和PeekPktIterator的基类，核心在于定义了`T& operator++()`函数。这也是一个模板类，在实例化时，是使用PktIterator和PeekPktIterator进行的实例化。 |
|PktIerator |继承至MessageIteratorBase<PktIterator>;class PktIterator : public MessageIteratorBase<PktIterator>; |
|PeekPktIterator |继承制MessageIteratorBase<PeekPktIterator>;class PeekPktIterator: public MessageIteratorBase<PeekPktIterator>; |


## MessageIteratorBase/PktIterator/PeekPktIterator

MessageIteratorBase是PktIterator和PeekPktIterator的基类，核心在于定义了`T& operator++()`函数。该函数中使用到了`OnAdvanceMessage`、`GetNextMessage`、`NotifyProcessedBytes`函数，其中前两者在下面的注释中做了解释。`NotifyProcessedBytes`函数将在后文MessageBatch章节进行介绍。

```C++
// 我们已经知道，T是 PktIterator / PeekPktIterator
// 当是 PktIterator 时， OnAdvanceMessage() 实际上调用了
// RxPipe::MessageBatch<PktIterator>::ConfirmBytes() 函数
// GetNextMessage() 实际上调用了 uint8_t* get_next_pkt(uint8_t* pkt);

// ---------------------------------------------------------------------

// 当是 PeekPktIterator时，
// OnAdvanceMessage() 是空函数
// GetNextMessage() 实际上调用了 uint8_t* get_next_pkt(uint8_t* pkt);
  constexpr T& operator++() {
    T* child = static_cast<T*>(this);

    uint32_t nb_bytes = next_addr_ - addr_;

    child->OnAdvanceMessage(nb_bytes);

    addr_ = next_addr_;
    next_addr_ = child->GetNextMessage(addr_);

    --missing_messages_;
    batch_->NotifyProcessedBytes(nb_bytes);

    return *child;
  }
```

下面解释一下`get_next_pkt()`函数：

```C++
_enso_always_inline uint16_t get_pkt_len(const uint8_t* addr) {
  const struct ether_header* l2_hdr = (struct ether_header*)addr;
  const struct iphdr* l3_hdr = (struct iphdr*)(l2_hdr + 1);
  const uint16_t total_len = be_to_le_16(l3_hdr->tot_len) + sizeof(*l2_hdr);

  return total_len;
}

// 这里实际上是假定了报文是64的整数倍，至于为啥不知道
// pkt是当前报文的首地址，返回值是下一个报文的首地址
// 每个报文都是一个完整的以太网帧
_enso_always_inline uint8_t* get_next_pkt(uint8_t* pkt) {
  uint16_t pkt_len = get_pkt_len(pkt);
  uint16_t nb_flits = (pkt_len - 1) / 64 + 1;
  return pkt + nb_flits * 64;
}
```



## MessageBatch

MessageBatch是一个模板类，仅使用PktIterator/PeekPktIterator进行了实例化。在这个类中，定义了`begin() end()` `buf()` 等函数，表现类似于C++中的迭代器。

该类定义了`NotifyProcessedBytes()`函数，仅在`MessageIteratorBase::++operator()`中被调用了，用于增加已经被处理了的字节数量。

该类仅在RxPipe和RxTxPipe类中有使用，是以下函数的返回值，我将在RxPipe中详细介绍RecvMessages函数。

```C++
MessageBatch<PeekPktIterator> PeekPkts(int32_t max_nb_pkts = -1);
MessageBatch<PktIterator> RecvPkts(int32_t max_nb_pkts = -1);
// 上面两个函数最终都调用到了 下面的 RecvMessages 函数

  /**
   * @brief Receives a batch of generic messages.
   *
   * @param T An iterator for the particular message type. Refer to
   *          `enso::PktIterator` for an example of a raw packet
   *          iterator.
   * @param max_nb_messages The maximum number of messages to receive. If set to
   *                        -1, all messages in the pipe will be received.
   *
   * @return A MessageBatch object that can be used to iterate over the received
   *         messages.
   */
  template <typename T>
  constexpr MessageBatch<T> RecvMessages(int32_t max_nb_messages = -1) {
    uint8_t* buf = nullptr;
    uint32_t recv = Peek(&buf, ~0);
    return MessageBatch<T>((uint8_t*)buf, recv, max_nb_messages, this);
  }
 
```



# echo流程

下面是以`software/examples/echo.cpp`绘制的流程图，并对关键代码进行了note说明。在后面的章节中将分别介绍RxPipe和TxPipe，RxTxPipe本质上可以视为前二者的组合。

在下面的流程图中，我们不难看出，对于上层应用而言，只需要重点掌握流程即可，比如使用Pipe的BIND函数来指定源端口、ip、目的端口、IP、以及协议类型等。

使用PIPE的PeekPkts()、RecvPkts()等函数来获取MessageBatch迭代器。

当使用MessageBatch作为迭代器来迭代访问数据时，获取到的指针是`uint8_t*`类型的，指向的数据是一个完整的以太网帧，因此需要用户自行去分析所有的网络栈协议。

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/MNnJbm5RkofW7KxqYHwcTojZnfb.png)

# RxPipe

## Bind函数

```C++
int Bind(uint16_t dst_port, uint16_t src_port, uint32_t dst_ip,
                  uint32_t src_ip, uint32_t protocol);
```

函数enso::RxTxPipe::Bind将管道绑定到给定的流条目。可以多次调用该函数以绑定到多个流。


当前硬件对于UDP数据包会忽略源IP和源端口。在绑定到UDP时，必须将它们设置为0。


绑定语义取决于网卡上实现的功能。更灵活的流控可能需要不同类型的绑定。
尽管不同网卡实现的绑定语义会有所不同，但这里描述的是伴随Enso的网卡实现的行为。

每次调用Bind()都会在网卡上创建一个新的流条目，该条目使用函数参数中指定的所有字段（5元组）。对于每个传入的数据包，网卡会尝试找到一个匹配的流条目。如果找到，则将数据包转发到相应的RX管道；如果未找到，则将数据包转发到其中一个回退队列。

用于查找匹配条目的字段取决于传入的数据包：

* 如果数据包协议为TCP（6）：
* 如果数据包协议为UDP（17），网卡在查找匹配流条目时只使用目标IP、目标端口和协议，其他所有字段都设置为0。
* 对于其他协议，网卡在查找匹配流条目时仅使用目标IP，其他所有字段都设置为0。

因此，如果要监听新的TCP连接，应将目标IP和端口绑定，并将其他所有字段设置为0。如果要接收来自已建立的TCP连接的数据包，应将所有字段绑定：目标IP、目标端口、源IP、源端口和协议。如果要接收UDP数据包，应将目标IP和端口绑定，并将其他所有字段设置为0。

参数

* dst_port 目标端口（小端）。
* src_port 源端口（小端）。
* dst_ip 目标IP（小端）。
* src_ip 源IP（小端）。
* protocol 协议（小端）。

返回值

* 成功返回0，其他情况返回不同的值。

# PeekPkts





![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/P2rfbbswJo3toxxZKBXcpiJonrh.png)



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/BHeZbVRS4obYzZxEQoec2vGdnpe.png)









# DEVICE

device类是单例模式，每个线程有且只能创建一个device，只能使用`Device::Create()`创建,会调用`Device::Init()`，在init函数中会调用`notification_buf_init()`初始化`Device::notification_buf_pair_`。

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/IT1cbyec6oPDAPx7oYPcN4U1nyt.png)

## Device::AllocateRxTxPipe

在`RxTxPipe::Init()`函数中，调用`Device::AllocateTxPipe()`时传入的参数是新分配的rx_pipe的缓冲区指针。

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/CUazbxMR5ooDjMxgLsycxQtpnhf.png)



