---
{"dg-publish":true,"page-title":"snippet/snippet/docs/linux/netlink/netlink-note.md at master · xgfone/snippet","url":"https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md","tags":null,"permalink":"/体系结构与操作系统/Linux内核/Linux Netlink 详解 转载/","dgPassFrontmatter":true}
---

转载自 https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md
## Linux Netlink 详解

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#linux-netlink-%E8%AF%A6%E8%A7%A3)

打开百度、谷歌搜索引擎一搜Netlink，发现大部分文章的介绍都是关于早期的Netlink版本（2.6.11版本），这些介绍及代码都已过时（差不多快10年了），连所使用的Linux版本最低的Redhat/CentOS也都无法编译这些代码了（关于这些接口的改变，请参见下文，但本文 不再介绍低于2.6.32版本的接口）。

## 说明

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E8%AF%B4%E6%98%8E)

现今，计算机之间的通信，最流行的TCP/IP协议。同一计算机之间的进程之间通信，经典方式是`系统调用`、`/sys`、`/proc`等，但是这些方式几乎都是用户空间主动向内核通信，而内核不能主动与用户空间通信；另外，这些方式实现起来不方便，扩展难，尤其是系统调用（内核会保持系统调用尽可能少————Linux一旦为某个系统调用分配了一个系统调用号后，就永远为它分配而不再改变，哪怕此系统调用不再使用，其相对应的系统调用号也不可再使用）。

为此，Linux首次提出了`Netlink`机制（现在已经以RFC形式提出国际标准），它基于Socket，可以解决上述问题：`用户空间可以主动向内核发送消息`，`内核既也可以主动向用户空间发送消息`，而且Netlink的扩展也十分方便————只需要以模块的方式向内核注册一下协议或Family（这是对于`Generic Netlink`而言）即可，不会污染内核，也不会过多的增加系统调用接口。

如果想要理解本文或Netlink机制， 可能需要明白Linux对Socket体系的实现方式（或者说是TCP/IP协议），比如：什么是`协议家族（Protocol Family）`、`地址家族（Address Family）`、`协议（Protocol）`、`Socket家族`、`Socket类型`等等。

Netlink虽然也是基于Socket，但只能用于同一台计算机中。Netlink Socket的标识是根据Port号来区分的，就像TCP/UDP Port一样，但Netlink Socket的Port号可达到`4`个字节。

Netlink是一种`Address Family`，同`AF_INET`、`AF_INET6`等一样，在此Family中可以定义多种Protocol（协议）。**`Netlink最多只允许定义32个协议，而且内核中已经使用了将近20个`**，也就是说，还剩余10个左右可以定义自己的协议。 另外，`Netlink数据的传输使用数据报（SOCK_DGRAM）形式`。因此，在用户空间创建一个Socket的形式如下（假设协议为XXX）：

fd \= socket(AF\_NETLINK, SOCK\_DGRAM, XXX);

或者

fd \= socket(AF\_NETLINK, SOCK\_RAW, XXX);

Netlink Socket即可以在内核创建，也可以在用户空间创建，因此有`内核Socket`和`用户空间Socket`。在使用Netlink Socket时，需要`先注册该Socket所属的协议`，**`注册时机是在创建内核Socket之时`**，换句话说就是，**`必须先创建一个内核Socket，在创建的同时，会注册该协议，然后用户空间的程序才可以创建这种协议的Socket`**。

虽然内核Socket和用户空间Socket都是Socket，但是有差别，就像内核空间与用户空间的地位一样，内核Socket比较特殊一些：**`所有内核Socket的Port号都是0`**,而\*\*`用户空间Socket的Port号是一个正数`\*\*（可以是任意值，随意指定，只要不重复就行，否则会报错），一般使用当前进程的PID，如果是在多线程中，可以使用线程ID。

对于不同版本的Linux内核，NETLINK接口有所变化，具体请参见下文的样例代码。

由于Netlink是基于Socket的，因此`通信是双向的`，也就是说，`内核既可以主动与用户空间通信`，`用户空间也可以主动与内核通信`，而且`用户空间Socket可以不经过内核Socket而直接与用户空间的其他Socket通信`。这就造成了三种通信方式：

```
（1）内核向用户空间发送消息；
（2）用户空间向内核发送消息；
（3）用户空间向用户空间发送消息。
```

有人会说，还有一种方式：内核向内核。但请注意，由于内核Socket比较特殊（其PortID永远都是0），因此内核向内核发送Netlink消息没有什么意义（注：这是可以的，不过最好不要这样做。在新版API中，在创建这样的内核Socket时，必须指定个compare函数）。

由于Netlink Socket是双向通信的，因此，

```
（1）既可以内核作为服务器，用户空间作为客户端（这样是经典模型）；
（2）也可以用户空间作为服务器，内核作为客户端；
（3）还可以用户空间作为服务器，另一个用户空间Socket作为客户端。
```

用户空间的Netlink Socket可以监听一组或几组多播组，只需要在创建时指定多播组即可。

**注：**

（1）**`只有用户空间的Socket才可以监听多播组，内核Socket不能监听多播组`**；另外，**`在用户空间，只有管理员才能监听多播组，普通用户只能创建单播Socket`**。因此，`广播/多播消息的承受者（即接收者）只能是用户空间Socket，实施者（即发送者）既可以是内核Socket，也可以是用户Socket`。

（2）`单播消息的承受者和实施者都可以是内核Socket或用户Socket`。

## 内核向用户空间发送消息

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E5%86%85%E6%A0%B8%E5%90%91%E7%94%A8%E6%88%B7%E7%A9%BA%E9%97%B4%E5%8F%91%E9%80%81%E6%B6%88%E6%81%AF)

内核向用户空间发送消息时使用`netlink_unicast`（单播）和`netlink_broadcast`（广播/多播）两个函数。其接口如下：

int netlink\_unicast(struct sock \*ssk, struct sk\_buff \*skb, u32 portid, int nonblock)
int netlink\_broadcast(struct sock \*ssk, struct sk\_buff \*skb, u32 portid, u32 group, gfp\_t allocation)

### 单播

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E5%8D%95%E6%92%AD)

#### 参数

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E5%8F%82%E6%95%B0)

**ssk**

```
在注册NETLINK协议时，创建的内核Socket。
```

**skb**

```
消息缓冲区，里面存放有将要发送给其他Socket的Netlink消息。
```

**portid**

```
接收此消息的用户Socket的Port号，如果是0，表示接收方是内核Socket；否则是用户空间Socket。
```

**nonblock**

```
此发送动作是否阻塞，直到消息成功发送才返回。此参数是新版Linux添加的，在旧API中没有这个参数。
```

#### 返回值

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E8%BF%94%E5%9B%9E%E5%80%BC)

如果发送失败（如没有Port号为portid的Socket），则返回错误码（一个负值）；如果成功，则返回实际发送的字节数。

#### 总结

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E6%80%BB%E7%BB%93)

如果要向用户空间Socket发送消息，则应将portid指定该Socket的Port号（一个正数）；一般不会指定为0（内核向内核发单播消息）。

### 多播

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E5%A4%9A%E6%92%AD)

#### 参数

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E5%8F%82%E6%95%B0-1)

**ssk**

```
在注册NETLINK协议时，创建的内核Socket。
```

**skb**

```
消息缓冲区，里面存放有将要发送给其他Socket的Netlink消息。
```

**portid**

```
排除具有portid的Socket，即Port号为此参数的Socket不允许接收此消息，一般指定为0。
```

**group**

```
接收此消息的组。用户Socket在创建时，会指明所监听的组。
```

**allocation**

```
在多播时，会为每个目的Socket复制一份skb；该参数指定，在复制skb时，如何分配缓冲区，一般使用GFP_ATOMIC。
```

#### 返回值

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E8%BF%94%E5%9B%9E%E5%80%BC-1)

如果成功，返回0；如果失败，返回错误码（一个负值）。

#### 处理流程

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E5%A4%84%E7%90%86%E6%B5%81%E7%A8%8B)

遍历组播表中的Socket（即打开监听组的用户Socket），如果此Socke监听的组和group参数一致（即过滤没有监听此组的用户Socket）且此Socket的Port与portid参数不一致（即过滤掉portid参数指定的Socket），则向此Socket发送一个消息（即复制一份skb，然后将新生成的skb放到目的Socket的接收队列上）。

#### 总结

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E6%80%BB%E7%BB%93-1)

如果要向用户空间发送多播消息，把group参数指定为要发送的一个或几个多播组；如果想要排除某个用户空间Socket（即不想让此Socket接收此多播消息），就把portid参数指定该Socket的Port号。portid一般指定为0，即不排除任何用户空间Socket。

## 用户空间向内核/用户空间发送消息

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E7%94%A8%E6%88%B7%E7%A9%BA%E9%97%B4%E5%90%91%E5%86%85%E6%A0%B8%E7%94%A8%E6%88%B7%E7%A9%BA%E9%97%B4%E5%8F%91%E9%80%81%E6%B6%88%E6%81%AF)

用户空间Netlink Socket使用的是通用Socket接口，因此发向某个其他Netlink Socket发送消息时，需要指定一个目的地址。

Netlink 地址家族的地址定义为：

struct sockaddr\_nl {
    \_\_kernel\_sa\_family\_t    nl\_family;   /\* AF\_NETLINK   \*/
    unsigned short          nl\_pad;      /\* zero         \*/
    \_\_u32                   nl\_pid;      /\* port ID      \*/
    \_\_u32                   nl\_groups;   /\* multicast groups mask \*/
}

`nl_family` 是地址家族，必须指定为 `AF_NETLINK`； `nl_pad` 是用来填充的（暂时保留），必须全部为`0`； `nl_pid` 是目的Socket的Port号，即要发送给哪个Socket，就指定为它的Port号； `nl_groups` 是要发送的多播组，即将Netlink消息发送给哪些多播组。

### 总结

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E6%80%BB%E7%BB%93-2)

**nl\_pid是用来发送单播的，nl\_groups是用来发送多播的。**

用户空间Socket无论发送单播还是多播，使用的是同一个系统调用，不同之处，只是上述地址传递的参数不同（`nl_pid`和`nl_groups`）。

### 其处理流程

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E5%85%B6%E5%A4%84%E7%90%86%E6%B5%81%E7%A8%8B)

```
（1）判断nl_groups是否为0，如果为0，则就只向Port号为nl_pid的Socket发送一个单播消息；
（2）如果nl_groups不为0（表示要发送多播），依次执行以下步骤：
    a. 向除Port号为nl_pid、且监听nl_groups指定的组的所有Socket发送一条此Netlink消息；
    b. 向Port号为nl_pid的Socket发送一条单播消息。

总之，无论单播还是多播，都要向Port号为nl_pid的Socket发送一条单播消息；
如果需要发送多播，则同时也向其他监听目的多播组的Socket发送消息。

注意：nl_pid指定的值必须存在，也就是说，必须有一个Socket的Port号为nl_pid，否则将返回一个错误。
```

#### 用户空间向内核发送单播

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E7%94%A8%E6%88%B7%E7%A9%BA%E9%97%B4%E5%90%91%E5%86%85%E6%A0%B8%E5%8F%91%E9%80%81%E5%8D%95%E6%92%AD)

```
将nl_pid指定为0, nl_groups指定为0。
```

#### 用户空间向用户空间发送单播

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E7%94%A8%E6%88%B7%E7%A9%BA%E9%97%B4%E5%90%91%E7%94%A8%E6%88%B7%E7%A9%BA%E9%97%B4%E5%8F%91%E9%80%81%E5%8D%95%E6%92%AD)

```
将nl_pid指定为目的Socket的Port号，nl_groups指定为0。
```

#### 用户空间向用户空间发送多播

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E7%94%A8%E6%88%B7%E7%A9%BA%E9%97%B4%E5%90%91%E7%94%A8%E6%88%B7%E7%A9%BA%E9%97%B4%E5%8F%91%E9%80%81%E5%A4%9A%E6%92%AD)

```
将nl_pid可指定为任意值（一般为0，即发送一条单播给内核），nl_groups指定为多播组。
```

#### 总结

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E6%80%BB%E7%BB%93-3)

```
发送单播时，nl_groups必须指定为0；发送多播时，nl_groups不能为0；无论是多播还是单播，nl_pid可以是任意值。
另外，无论是单播还是多播，都会向nl_pid指定的Socket发送一条单播消息。
```

## NETLINK 消息结构

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#netlink-%E6%B6%88%E6%81%AF%E7%BB%93%E6%9E%84)

NETLINK是个网络协议且使用了Socket框架，就会涉及到消息缓冲区、协议等。但不像TCP/IP协议有多层，Netlink协议只有到一层，也就是说，在用户发送的真实消息体前只有一个Netlink协议头。其协议格式如下（下述格式由于博客、空间的显式，导致有些错位）：

```
<--- nlmsg_total_size(payload)------->
<-- nlmsg_msg_size(payload) -->
+----------+- - -+-------------+- - -+
| nlmsghdr | Pad |   Payload   | Pad |
+----------+- - -+-------------+- - -+
nlmsg_data(nlh)---^
```

如果有多个Netlink消息时，其格式如下：

```
 <--- nlmsg_total_size(payload)  --->
 <-- nlmsg_msg_size(payload) ->
+----------+- - -+-------------+- - -+------------
| nlmsghdr | Pad |   Payload   | Pad | nlmsghdr
+----------+- - -+-------------+- - -+------------
nlmsg_data(nlh)---^                   ^
nlmsg_next(nlh)-----------------------+
```

其中，`nlmsg_data`、`nlmsg_next`、`nlmsg_msg_size`、`nlmsg_total_size`这些函数是内核定义的辅助函数，用来获取Netlink消息中相应某部分数据的起始位置或长度的。

Netlink消息头格式在Linux内核中定义如下：

struct nlmsghdr {
    \_\_u32       nlmsg\_len;      /\* Length of message including header \*/
    \_\_u16       nlmsg\_type;     /\* Message content \*/
    \_\_u16       nlmsg\_flags;    /\* Additional flags \*/
    \_\_u32       nlmsg\_seq;      /\* Sequence number \*/
    \_\_u32       nlmsg\_pid;      /\* Sending process port ID \*/
};

`nlmsg_len` 是包含消息头在内的整个Netlink消息缓冲区的长度； `nlmsg_type` 是此消息的类型； `nlmsg_flags` 是此消息的附加标志； `nlmsg_seq` 是此消息的序列号（可用于调试用）； `nlmsg_pid` 是发送此消息的Socket的Port号。

注：`nlmsg_type`、`nlmsg_flags`、`nlmsg_seq`一般没什么必要性，可以设为`0`。如果高级应用（比如路由），可以将`nlmsg_type`、`nlmsg_flags`指定为相应的值。因此，一般只需要设置`nlmsg_len`和`nlmsg_pid`两个值（其他的所有值都设为`0`）即可。另外，`nlmsg_pid`一定要设置成当前发送此消息的Socket的Port号，不然会出现一些问题，比如：如果内核或其他的Socket收到此消息并会向`nlmsg_pid`发送回复性的单播消息时，此Socket就无法收到回复消息了。

## 使用Netlink的步骤

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E4%BD%BF%E7%94%A8netlink%E7%9A%84%E6%AD%A5%E9%AA%A4)

```
(1) 首先在内核创建一个内核Socket并注册一个协议（一般放在系统启动或内核模块初始化之时）；
(2) 在用户空间创建一个Netlink Socket；
(3) 内核作为服务端或者用户空间用为服务端：
    内核作为服务端：
        用户空间首先向内核发送消息，内核回应此消息。
    用户空间作为服务端：
        内核首先向用户空间发送消息（必须知道用户Socket的Port号或者发送多播组），然后用户空间Socket回应消息。
```

**注：**

Netlink的使用关键是消息的发送，在发送之前，要构建Netlink消息包。

构建Netlink消息包，无论内核还是用户空间，都要构造Netlink消息头；但在内核中，一般还要设置Netlink Socket控制块。

## 样例

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E6%A0%B7%E4%BE%8B)

以下代码，默认是内核作为服务端，用户空间作为客户端。但已经另外预留了接口，稍微修改一下，即可以变为用户空间作为服务端，内核作为客户端。

内核作为客户端有个要求，需要有个时机去触发内核主动向用户空间发送消息。

注：这个时机不能是内核Socket创建之时，也就是说，不能在创建内核Socket之后立即向用户空间发送消息，因为此时用户空间还没有创建用户空间的Netlink Socket。我在测试时，一般使用另一个内核模块来触发（在加载模块之时）。

内核模块已经预留接口，并且已经将这些接口作为导出符号导出（在其他模块中可直接使用）：

int test\_unicast(void \*data, size\_t size, \_\_u32 pid);
int test\_broadcast(void \*data, size\_t size, \_\_u32 group);

只需要调用以上函数中的任何一个，内核就可以向用户空间发送单播或多播消息。

注：以下代码，在 `Ubuntu 14.04 64 Bit` 和 `Deepin 2014 64 Bit` 下测试成功；如果编译失败，请检查内核版本是否正确，以下代码默认要求 `Linux 3.8` 以上，如果低于 `3.8`，请根据注释换成相应的接口；`CentOS 6` 使用的 Linux 内核是 `2.6.32` 的，请根据注释换成相应的接口。如果是在加载内核模块时失败，请检查

```
（1）内核模块名是不是 kernel.ko（第三方内核模块不允许为kernel.ko，因为这个名字已经被Linux内核自身使用了）；
（2）NETLINK_TEST 宏值是否已经被使用了，如果被使用了，请换成一个没有被使用过的（17 很容易被使用，故以下代码改成了 30）。
```

### 内核模块文件netlink\_kernel.c

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E5%86%85%E6%A0%B8%E6%A8%A1%E5%9D%97%E6%96%87%E4%BB%B6netlink_kernelc)

#include <linux/module.h>
#include <net/sock.h>
#include <linux/netlink.h>
#include <linux/skbuff.h>

#define NETLINK\_TEST 30

static struct sock \*nl\_sk \= NULL;

/\*
 \* Send the data of \`data\`, whose length is \`size\`, to the socket whose port is \`pid\` through the unicast.
 \*
 \* @param data: the data which will be sent.
 \* @param size: the size of \`data\`.
 \* @param pid: the port of the socket to which will be sent.
 \* @return: if successfully, return 0; or, return -1.
 \*/
int test\_unicast(void \*data, size\_t size, \_\_u32 pid)
{
    struct sk\_buff \*skb\_out;
    skb\_out \= nlmsg\_new(size, GFP\_ATOMIC);
    if(!skb\_out) {
        printk(KERN\_ERR "Failed to allocate a new sk\_buff\\n");
        return \-1;
    }

    //struct nlmsghdr\* nlmsg\_put(struct sk\_buff \*skb, u32 portid, u32 seq, int type, int len, int flags);
    struct nlmsghdr \* nlh;
    nlh \= nlmsg\_put(skb\_out, 0, 0, NLMSG\_DONE, size, 0);

    memcpy(nlmsg\_data(nlh), data, size);

    // 设置 SKB 的控制块（CB）
    // 控制块是 struct sk\_buff 结构特有的，用于每个协议层的控制信息（如：IP层、TCP层）
    // 对于 Netlink 来说，其控制信息是如下结构体：
    // struct netlink\_skb\_parms {
    //      struct scm\_credscreds;  // Skb credentials
    //      \_\_u32portid;            // 发送此SKB的Socket的Port号
    //      \_\_u32dst\_group;         // 目的多播组，即接收此消息的多播组
    //      \_\_u32flags;
    //      struct sock\*sk;
    // };
    // 对于此结构体，一般只需要设置 portid 和 dst\_group 字段。
    // 但对于不同的Linux版本，其结构体会所有变化：早期版本 portid 字段名为 pid。
    //NETLINK\_CB(skb\_out).pid = pid;
    NETLINK\_CB(skb\_out).portid \= pid;
    NETLINK\_CB(skb\_out).dst\_group \= 0;  /\* not in mcast group \*/

    // 单播/多播
    if(nlmsg\_unicast(nl\_sk, skb\_out, pid) < 0) {
        printk(KERN\_INFO "Error while sending a msg to userspace\\n");
        return \-1;
    }

    return 0;
}
EXPORT\_SYMBOL(test\_unicast);

/\*
 \* Send the data of \`data\`, whose length is \`size\`, to the socket which listens
 \* the broadcast group of \`group\` through the broadcast.
 \*
 \* @param data: the data which will be sent.
 \* @param size: the size of \`data\`.
 \* @param group: the broadcast group which the socket listens, to which will be sent.
 \* @return: if successfully, return 0; or, return -1.
 \*/
int test\_broadcast(void \*data, size\_t size, \_\_u32 group)
{
    struct sk\_buff \*skb\_out;
    skb\_out \= nlmsg\_new(size, GFP\_ATOMIC);
    if(!skb\_out) {
        printk(KERN\_ERR "Failed to allocate a new sk\_buff\\n");
        return \-1;
    }

    //struct nlmsghdr\* nlmsg\_put(struct sk\_buff \*skb, u32 portid, u32 seq, int type, int len, int flags);
    struct nlmsghdr \* nlh;
    nlh \= nlmsg\_put(skb\_out, 0, 0, NLMSG\_DONE, size, 0);

    memcpy(nlmsg\_data(nlh), data, size);

    // NETLINK\_CB(skb\_out).pid = 0;
    NETLINK\_CB(skb\_out).portid \= 0;
    NETLINK\_CB(skb\_out).dst\_group \= group;

    // 多播
    // int netlink\_broadcast(struct sock \*ssk, struct sk\_buff \*skb, \_\_u32 portid, \_\_u32 group, gfp\_t allocation);
    if (netlink\_broadcast(nl\_sk, skb\_out, 0, group, GFP\_ATOMIC) < 0) {
        printk(KERN\_ERR "Error while sending a msg to userspace\\n");
        return \-1;
    }

    return 0;
}
EXPORT\_SYMBOL(test\_broadcast);

static void nl\_recv\_msg(struct sk\_buff \*skb)
{
    struct nlmsghdr \*nlh \= (struct nlmsghdr\*)skb\->data;
    char \*data \= "Hello userspace";
    printk(KERN\_INFO "==== LEN(%d) TYPE(%d) FLAGS(%d) SEQ(%d) PORTID(%d)\\n", nlh\->nlmsg\_len, nlh\->nlmsg\_type,
           nlh\->nlmsg\_flags, nlh\->nlmsg\_seq, nlh\->nlmsg\_pid);
    printk("Received %d bytes: %s\\n", nlmsg\_len(nlh), (char\*)nlmsg\_data(nlh));
    test\_unicast(data, strlen(data), nlh\->nlmsg\_pid);
}

static int \_\_init test\_init(void)
{
    printk("Loading the netlink module\\n");

    /\*
    // Args:
    //      net:   &init\_net
    //      unit:  User-defined Protocol Type
    //      input: the callback function when received the data from the userspace.
    //
    // 3.8 kernel and above
    // struct sock\* \_\_netlink\_kernel\_create(struct net \*net, int unit,
    //                                      struct module \*module,
    //                                      struct netlink\_kernel\_cfg \*cfg);
    // struct sock\* netlink\_kernel\_create(struct net \*net, int unit, struct netlink\_kernel\_cfg \*cfg)
    // {
    //     return \_\_netlink\_kernel\_create(net, unit, THIS\_MODULE, cfg);
    // }
    //
    //
    // 3.6 or 3.7 kernel
    // struct sock\* netlink\_kernel\_create(struct net \*net, int unit,
    //                                    struct module \*module,
    //                                    struct netlink\_kernel\_cfg \*cfg);
    //
    // 2.6 - 3.5 kernel
    // struct sock \*netlink\_kernel\_create(struct net \*net,
    //                                    int unit,
    //                                    unsigned int groups,
    //                                    void (\*input)(struct sk\_buff \*skb),
    //                                    struct mutex \*cb\_mutex,
    //                                    struct module \*module);
    \*/

    /\*
    // This is for the kernels from 2.6.32 to 3.5.
    nl\_sk = netlink\_kernel\_create(&init\_net, NETLINK\_TEST, 0, nl\_recv\_msg, NULL, THIS\_MODULE);
    if(!nl\_sk) {
        printk(KERN\_ALERT "Error creating socket.\\n");
        return -10;
    }
    \*/

    //This is for 3.8 kernels and above.
    struct netlink\_kernel\_cfg cfg \= {
        .input \= nl\_recv\_msg,
    };

    nl\_sk \= netlink\_kernel\_create(&init\_net, NETLINK\_TEST, &cfg);
    if(!nl\_sk) {
        printk(KERN\_ALERT "Error creating socket.\\n");
        return \-10;
    }

    return 0;
}

static void \_\_exit test\_exit(void) {
    printk(KERN\_INFO "Unloading the netlink module\\n");
    netlink\_kernel\_release(nl\_sk);
}

module\_init(test\_init);
module\_exit(test\_exit);
MODULE\_LICENSE("GPL");

### 用户空间程序文件netlink\_user.c

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E7%94%A8%E6%88%B7%E7%A9%BA%E9%97%B4%E7%A8%8B%E5%BA%8F%E6%96%87%E4%BB%B6netlink_userc)

#include <stdint.h>
#include <sys/socket.h>
#include <linux/netlink.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define NETLINK\_TEST    30
#define MAX\_PAYLOAD     1024    /\* maximum payload size\*/
#define MAX\_NL\_BUFSIZ   NLMSG\_SPACE(MAX\_PAYLOAD)

//int PORTID = getpid();
int PORTID \= 1;

int create\_nl\_socket(uint32\_t pid, uint32\_t groups)
{
    int fd \= socket(PF\_NETLINK, SOCK\_RAW, NETLINK\_TEST);
    if (fd \== \-1) {
        return \-1;
    }

    struct sockaddr\_nl addr;
    memset(&addr, 0, sizeof(addr));
    addr.nl\_family \= AF\_NETLINK;
    addr.nl\_pid \= pid;
    addr.nl\_groups \= groups;

    if (bind(fd, (struct sockaddr \*)&addr, sizeof(addr)) != 0) {
        close(fd);
        return \-1;
    }

    return fd;
}

ssize\_t nl\_recv(int fd)
{
    char nl\_tmp\_buffer\[MAX\_NL\_BUFSIZ\];
    struct nlmsghdr \*nlh;
    ssize\_t ret;

    // 设置 Netlink 消息缓冲区
    nlh \= (struct nlmsghdr \*)&nl\_tmp\_buffer;
    memset(nlh, 0, MAX\_NL\_BUFSIZ);

    ret \= recvfrom(fd, nlh, MAX\_NL\_BUFSIZ, 0, NULL, NULL);
    if (ret < 0) {
        return ret;
    }

    // // 通过MSG结构体来发送信息
    // struct iovec iov;
    // struct msghdr msg;
    // iov.iov\_base = (void \*)nlh;
    // iov.iov\_len = MAX\_NL\_BUFSIZ;
    // msg.msg\_name = (void \*)&addr;
    // msg.msg\_namelen = sizeof(\*addr);
    // msg.msg\_iov = &iov;
    // msg.msg\_iovlen = 1;
    // ret = recvmsg(fd, &msg, 0);
    // if (ret < 0) {
    // return ret;
    // }

    printf("==== LEN(%d) TYPE(%d) FLAGS(%d) SEQ(%d) PID(%d)\\n\\n", nlh\->nlmsg\_len, nlh\->nlmsg\_type,
           nlh\->nlmsg\_flags, nlh\->nlmsg\_seq, nlh\->nlmsg\_pid);
    printf("Received data: %s\\n", NLMSG\_DATA(nlh));
    return ret;
}

int nl\_sendto(int fd, void \*buffer, size\_t size, uint32\_t pid, uint32\_t groups)
{
    char nl\_tmp\_buffer\[MAX\_NL\_BUFSIZ\];
    struct nlmsghdr \*nlh;

    if (NLMSG\_SPACE(size) \> MAX\_NL\_BUFSIZ) {
        return \-1;
    }

    struct sockaddr\_nl addr;
    memset(&addr, 0, sizeof(addr));
    addr.nl\_family \= AF\_NETLINK;
    addr.nl\_pid \= pid;          /\* Send messages to the linux kernel. \*/
    addr.nl\_groups \= groups;    /\* unicast \*/

    // 设置 Netlink 消息缓冲区
    nlh \= (struct nlmsghdr \*)&nl\_tmp\_buffer;
    memset(nlh, 0, MAX\_NL\_BUFSIZ);
    nlh\->nlmsg\_len \= NLMSG\_LENGTH(size);
    nlh\->nlmsg\_pid \= PORTID;
    memcpy(NLMSG\_DATA(nlh), buffer, size);

    return sendto(fd, nlh, NLMSG\_LENGTH(size), 0, (struct sockaddr \*)&addr, sizeof(addr));

    // // 通过MSG结构体来发送信息
    // struct iovec iov;
    // struct msghdr msg;
    // iov.iov\_base = (void \*)nlh;
    // iov.iov\_len = nlh->nlmsg\_len;
    // msg.msg\_name = (void \*)dst\_addr;
    // msg.msg\_namelen = sizeof(\*dst\_addr);
    // msg.msg\_iov = &iov;
    // msg.msg\_iovlen = 1;
    // return sendmsg(sock\_fd, &msg, 0);
}

int main(void)
{
    char data\[\] \= "Hello kernel";
    int sockfd \= create\_nl\_socket(PORTID, 0);
    if (sockfd \== \-1) {
        return 1;
    }

    int ret;
    ret \= nl\_sendto(sockfd, data, sizeof(data), 0, 0);
    if (ret < 0) {
        printf("Fail to send\\n");
        return 1;
    }
    printf("Sent %d bytes\\n", ret);

    ret \= nl\_recv(sockfd);
    if (ret < 0) {
        printf("Fail to receive\\n");
    }
    printf("Received %d bytes\\n", ret);

    // while (1) {
    // nl\_recv(sockfd);
    // nl\_sendto(sockfd, data, sizeof(data), 0, 0);
    // }

    return 0;
}

### Makefile文件

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#makefile%E6%96%87%E4%BB%B6)

KBUILD\_CFLAGS += -w
obj-m += netlink\_kernel.o

all:
    make -w -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
    make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

### 构造方法

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E6%9E%84%E9%80%A0%E6%96%B9%E6%B3%95)

#### 编译内核模块

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E7%BC%96%E8%AF%91%E5%86%85%E6%A0%B8%E6%A8%A1%E5%9D%97)

切换到该目录下，直接执行 `make` 即可，如：

#### 编译用户空间程序

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E7%BC%96%E8%AF%91%E7%94%A8%E6%88%B7%E7%A9%BA%E9%97%B4%E7%A8%8B%E5%BA%8F)

gcc netlink\_user.c -o netlink\_user

#### 安装内核模块

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E5%AE%89%E8%A3%85%E5%86%85%E6%A0%B8%E6%A8%A1%E5%9D%97)

sudo insmod ./netlink\_kernel.ko

#### 启动用户空间程序

[](https://github.com/xgfone/snippet/blob/master/snippet/docs/linux/netlink/netlink-note.md#%E5%90%AF%E5%8A%A8%E7%94%A8%E6%88%B7%E7%A9%BA%E9%97%B4%E7%A8%8B%E5%BA%8F)