---
{"dg-publish":true,"date":"2024-01-15","time":"12:31","progress":"进行中","tags":["论文","分布式系统"],"permalink":"/分布式系统/Raft共识算法/","dgPassFrontmatter":true}
---


# Raft共识算法


## 论文基本信息

|类别|描述|
|---|---|
|题目|In Search of an Understandable Consensus Algorithm<br> |
|期刊||
|期刊级别||
|发表时间||
|第一作者|Diego Ongaro |
|第一作者单位|Stanford University |

## 声明

本文为本人原创，未经授权严禁转载。如需转载需要在文章最前面注明本文原始链接。
主要学习资料：[解读共识算法Raft](https://www.bilibili.com/video/BV1pr4y1b7H5/?spm_id_from=333.337.search-card.all.click&vd_source=47bbcc428387a807dfb9a0a62d6b09d1 )


## 摘要

Raft是用于管理日志复制的共识算法，它的效果等同于多paxos.  复制状态机用于解决分布式系统中的各种容错问题，复制状态机通常使用日志复制来实现。

每个服务器都存储一个包含一系列命令的日志，这些命令按顺序由其状态机执行。每条日志中的命令以相同的顺序包含相同的命令，因此每个状态机都会处理相同的一系列命令。由于状态机是确定性的，所以每个状态机都会计算出相同的状态和输出序列。

保持复制日志的一致性是共识算法的工作。

## 算法特点

Raft 通过首先选举一个特定的领导者，然后赋予该领导者完全负责管理复制日志的责任来实现共识。领导者接收来自客户端的日志条目，并在其他服务器上进行复制，同时指示服务器何时可以将日志条目安全地应用到它们的状态机中。拥有领导者简化了复制日志的管理。例如，领导者可以在不咨询其他服务器的情况下决定在日志中的新条目放置位置，数据以一种简单的形式从领导者流向其他服务器。领导者可能会失效或与其他服务器断开连接，在这种情况下会选举新的领导者。

与传统的Paxos算法相比，Raft协议具有以下优点：

1. 更容易理解和实现：Raft协议的设计更加简单直观，易于理解和实现。
2. 更好的容错性能：Raft协议通过选举机制和日志复制机制来保证系统的高可用性和容错性能。
3. 更好的可扩展性：Raft协议支持动态添加或删除节点，可以方便地进行水平扩展。

Raft将共识问题分成三个相对独立的子问题：
- 领导选举：当现有的领导运行失败时必须选举出 一个新的领导。一个完整的系统有且仅有一个领导。
- 日志复制：领导必须从客户端接受日志并将他们复制到集群中，并强制其他日志与领导的日志保持一致
- 安全性：Raft 的关键安全属性是图 3 中的状态机安全性属性：如果任何服务器已将其应用于状态机，则其他服务器不得为同一日志索引应用不同的命令。

## 算法概述
### 状态
在任何时刻，每一个服务器节点都处于leader,follower或candidate这三个状态之一。
相比于Paxos,这一点就极大简化了算法的实现，因为Raft只需考虑状态的切换，而不用像Paxos那样考虑状态之间的共存和互相影响。
![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240115183637.png)


![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240115184429.png)


![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240115184919.png)
  


![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240115130000.png)

### RPC
raft的心跳是一种特殊的 AppendEntries RPC，心跳中没有日志体，当仍然传递leaderCommit参数，告知之前的日志被提交了。

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240115130038.png)

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240115130023.png)

### 安全规则

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240115130053.png)

## 领导者选举

每个服务器上都维护一个term（任期号）和随机的超时器。

Raft内部有一种心跳机制，如果存在leader,那么它就会周期性地向所有follower发送心跳，来维持自己的地位。

如果follower一段时间没有收到心跳，那么他就会认为系统中没有可用的 leader了，然后开始进行选举。


开始一个选举过程后，超时的follower先增加自己的当前任期号，并转换到candidate状态。然后投票给自己，并且并行地向集群中的其他服务器节点发送投票请求(RequestVote RPC)。

收到投票请求的节点，会检查自身的term,如果大于candidate的term就拒绝，否则就将自身的term修改为candidate的term且将自身状态修改为 follower，然后会按照先到先得的原则向第一个 candidate 投赞成票，其他的candidate投反对票。candidate向其他candidate只会投反对票，除非任期小于另一个candidate。（在投票之前需要做检查，1. 如果candidate发送的term小于当前节点的term就拒绝 2. 如果当前节点也是 candidate那么也会拒绝）

如果某个candiate收到了超过半数的赞成票，就自动成为leader，并向其他节点发送心跳。

某个candidate在收到了新 leader 的心跳之后，如果新leader的任期号不小于自己当前的任期号，那么就从candidate回到 follower 状态。

如果没有任何一个candidate成为leader,那么就会在自己的随机选举超时只会，增加自身的任期号，开始新一轮的选举。

假设在一次投票选举中，所有的candidate都没有得到超过半数的票，那么，所有的节点都会假设有一个节点成为了 leader 然后等待心跳，如果有节点超时，那么该节点就会递增 term ，如果为 follower 状态，那么就转换为 candidate 状态。新一轮的竞选开始了。

### CLIENT如何找新LEADER

1. 向旧leader发送消息，如果当前节点依然是leader那么就成功了，如果不是，该节点可以从心跳机制中得知新leader是谁然后告知client
2. 如果与client通信的节点宕机，那么就向下一节点发送请求

此外还有引入第三方节点的机制。

## 日志复制

leader 并行地向 follower 发送AppendEntries RPC，让他们复制该条目。当该条目被超过半数的follower复制之后，leader就可以在本地执行该指令并把结果返回给客户端。**我们把本地执行指令的过程称为日志提交**。

日志中的每个条目需要包含以下信息：
- 状态机指令
- leader 的任期号
- 日志号

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240115202700.png)


### 日志提交
我们将日志应用到当前状态机的操作称之为日志提交，因此提交是一个单机的概念，而非集群的概念。在raft算法中，一定是leader先提交，然后通知其他节点可以提交了。

值得注意的是：**过半数的节点写入了日志是leader提交该日志的必要条件，而非充分条件**。

### 容错
在日志复制过程中，leader或follower随时都有崩溃或缓慢的可能性，Raft必须要在有宕机的情况下继续支持日志复制，并且保证每个副本日志顺序的一致（以保证复制状态机的实现)。具体有以下几种可能：
#### follower崩溃

1. 如果有follower因为某些原因没有给leader响应，那么leader会不断地重发追加条目请求(AppendEntries RPC),哪怕leader已经回复了客户端。
2. 如果有follower崩溃后恢复，这时Raft追加条目的一致性检查生效，保证follower能按顺序恢复崩溃后的缺失的日志。 Raft的一致性检查：leader在每一个发往follower的追加条目RPC中，会放入前一个日志条目的索引位置和任期号，如果follower在它的日志中找不到前一个日志，那么它就会拒绝此日志，leader收到follower的拒绝后，会发送前一个日志条且，从而逐渐向前定位到follower第一个缺失的日志。

#### leader崩溃

如果leader崩溃，那么崩溃的leader可能已经复制了日志到部分follower，但还没有提交。而被选出的新leader又可能不具备这些日志，这样就有部分follower中的日志和新leader的日志不相同。Raft在这种情况下，leader通过强制follower复制它的日志来解决不一致的问题，这意味着follower中跟leader冲突的日志条目会被新 leader的日志条目覆盖（因为没有提交，所以不违背外部一致性)

但是leader崩溃有很多的边界情况需要讨论：
1. 如果一个follower落后了leader若干条日志（但没有漏一整个任期)，那么下次选举中按照领导者选举里的规则，它依旧有可能当选leader。它在当选新leader后就永远也无法补上之前缺失的那部分日志，从而造成状态机之间的不一致。所以需要对领导者选举增加一个限制，保证被选出来的leader一定包含了之前各任期的所有已经被集群提交的日志条目（所谓集群提交是指包括旧leader在内的超过半数的节点都提交了）。（见 [[分布式系统/Raft共识算法#^e8c039\|选举限制]] ，该限制可以保证新leader一定具有旧leader已提交的日志的）
2. 新选举出的leader不具备某个日志（由于条件1, 该日志一定是未在任何节点上提交的），但是该日志已经被旧leader复制到了超过半数的节点上了。（见 [[分布式系统/Raft共识算法#^67f9c3\|#^67f9c3]]）
3. 旧leader在本地执行了客户端的请求（也就是在本地提交了），但是在将日志提交的信息发送给follower之前宕机了，就会出现在集群中未提交的状态。此时新选举出的leader可能会重复旧leader与client的交互，但是raft是集群的共识算法，不涉及与客户端的共识，为了解决这个问题，需要在客户端与leader交互的过程中解决，参见[[分布式系统/分布式事务模型Percolator\|分布式事务模型Percolator]]。raft能够保证的是，尽管旧日志仅在旧leader上提交了，但是最终也会在集群中的其他节点上也被提交的。



## 安全性

领导者选举和日志复制两个子问题已经涵盖了共识算法的全程，但是这两点还不能完全保证**每一个状态机会按照相同的顺序执行相同的命令**。

### 选举限制
{ #e8c039}


该限制保证了：**只有拥有最新的日志的节点才能当选leader**.

该限制与集群提交的限制规则、leader必须获得过半选票规则保证了：**凡是被选为leader的节点，一定包含了所有被提交了的日志，其他节点上拥有但新leader没有的一定全部都是未在任何一个节点提交的**。

如果一个follower落后了leader若干条日志（但没有漏一整个任期)，那么下次选举中按照领导者选举里的规则，它依旧有可能当选leader。它在当选新leader后就永远也无法补上之前缺失的那部分日志，从而造成状态机之间的不一致。所以需要对领导者选举增加一个限制，保证被选出来的leader一定包含了之前各任期的所有被提交的日志条目。

RequestVote RPC执行了这样的限制：RPC中包含了candidate的日志信息，如果投票者自己的日志比candidate的还新，它会拒绝掉该投票请求。

Raft通过比较两份日志中最后一条日志条目的索引值和任期号来定义谁的日志比较新：
- 如果两份日志最后条目的任期号不同，那么任期号大的日志更“新”。
- 如果两份日志最后条目的任期号相同，那么日志号更大的那个更“新”。



### leader的宕机处理
{ #67f9c3}


该限制是为了讨论：新leader是否提交之前任期内的日志条目。

1. 如果新选举出的leader具备所有旧leader的日志，只是未提交，那么新leader只会在产生新的日志之后，提交新日志的同时将旧leader的日志进行提交。之所以新leader选举出来之后不会立即对已有的日志进行提交，是为了防止新leader在leader节点提交和集群提交之间宕机，如果宕机了，然后选举出了新的leader,而最新的leader不具备之前的日志的话，就会产生不一致的行为。但是如果新产生了日志，该新日志被提交的前提是过半节点拥有了该日志（拥有新日志就说明旧日志也已经复制到了过半节点之上），如果此时新leader在leader节点提交和集群提交之间宕机的话，并不会造成不一致性。因为新产生的日志已经被复制到了过半节点上了，根据[[分布式系统/Raft共识算法#^e8c039\|选举限制]]和过半选票规则，最新的leader一定是拥有最新产生的日志的，因此不会造成不一致性。

2. 假设新选举出的leader不具备旧leader未提交的日志。那么新leader的日志就会覆盖其它节点未提交的日志。这并不会产生一致性问题。首先，既然该leader能够被选举成功，那么根据[[分布式系统/Raft共识算法#^e8c039\|选举限制]] 非leader节点的日志一定是未提交的，且该日志一定是比新leader的最新日志旧的，那么对这些日志进行覆盖是没有问题的。

### follower和candidate宕机处理

- Follower和Candidate崩溃后的处理方式是相同的。
- 如果follower或candidate崩溃了，那么后续发送给他们的RequestVote和AppendEntries RPCs都会失败。
- Raft通过无限的重试来处理这种失败。如果崩溃的机器重启了，那么这些RPC就会成功地完成。
- 如果一个服务器在完成了一个RPC,但是还没有相应的时候崩溃了，那么它重启之后就会再次收到同样的请求。(Raft的RPC都是幂等的，所谓幂等就是重复执行不会出现问题)

### 时间与可用性限制

- raft算法整体不依赖客观时间，也就是说，哪怕因为网络或其他因素，造成后发的RPC先到，也不会影响raft的正确性。
- 只要整个系统满足下面的时间要求，Raft就可以选举出并维持一个稳定的leader：
	- 广播时间(broadcastTime)<<选举超时时间(electionTimeout)<<平均故障时间(MTBF)
	- 广播时间和平均故障时间是由系统决定的，但是选举超时时间是我们自己选择的。Raft的 RPC需要接受并将信息落盘，所以广播时间大约是0.5ms到20ms,取决于存储的技术。因此，选举超时时间可能需要在10ms到500ms之间。大多数服务器的平均故障间隔时间都在几个月甚至更长。

## 集群成员变更

事实上论文对这里的讨论是很复杂的，详情可见 https://www.bilibili.com/video/BV11u411y7q9/?spm_id_from=333.788&vd_source=47bbcc428387a807dfb9a0a62d6b09d1


在需要改变集群配置的时候（如增减节点、替换宕机的机器或者改变复制的程度），Raft可以进行配置变更自动化。自动化配置变更机制最大的难点是保证转换过程中不会出现同一任期的两个leader, 因为转换期间整个集群可能划分为两个独立的大多数（新配置和旧配置）。

配置采用了两阶段的方法：集群先切换到一个过渡的配置，称之为联合一致(joint consensus)。

第一阶段，leader发起$C{old,new}$,使整个集群进入联合一致状态。这时，所有RPC都要在新旧两个配置中都达到大多数才算成功。
第二阶段，leader2发起$C_{new}$,使整个集群进入新配置状态。这时，所有RPC只要在新配置下能达到大多数就算成功。

只要节点收到了集群配置变更日志并将其加到了自己的日志中，那么该配置不必等待集群提交就可以直接使用了。但是这并不代表集群提交失效，只是配置应用本身不会等日志提交之后才会执行。也就是说，即使集群配置变更日志没有被集群提交，节点也可能已经使用了新的配置。

在集群配置变更过程中，leader可能随时崩溃，会有以下几种情况：
1. 在$C{old,new}$未提交时宕机
2. 在$C{old,new}$已提交，但$C_{new}$未发起时宕机
3. 在$C{old,new}$已提交，$C_{new}$已发起但未提交时宕机

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240116165458.png)


## 总结
主要参考自 https://www.bilibili.com/video/BV1q5411R74n/?spm_id_from=333.788&vd_source=47bbcc428387a807dfb9a0a62d6b09d1

### 深入理解复制状态机

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240116205319.png)
![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240116205406.png)
![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240116205752.png)

### 共识算法的三个主要特性
![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240116205857.png)


![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240116210107.png)

长生命周期的leader是raft实现简单，并区别于其他共识算法的最关键点。

### no-op补丁
![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240116210400.png)
### 集群成员变更拓展

联合一致集群成员变更方法比较复杂，不契合raft的易理解性。在Diego Ongaro的博士论文，和后续的大部分对raft实现中，都使用的是另一种更简单的单节点并更方法，**即一次只增减一个节点，称为单节点集群成员变更方法**。**每次只增减一个节点，相比于多节点变更，最大的差异是新旧配置集群的大多数，是一定会有重合的**。

#### 新增节点
当新增一个节点时，首先要对新节点与leader进行日志同步。由于在同步过程中，leader依然在不断接受新日志，因此新增节点需要经过多轮同步。例如，同步十轮之后，我们就可以认为新增节点与集群中的follower节点基本一致了。

此时，leader产生并发送$C_{new}$，当leader产生了$C_{new}$之后就开始使用新配置了，只有当集群中的过半节点都接受到了新配置之后，才会对新配置进行提交。（此时只有leader有新配置，加入它宕机了，剩余的节点依然使用旧配置，他们会选举出新的leader,因此不会破坏可用性）。

当过半节点都接收了新配置之后，新配置日志会被提交，但节点集群就变更完成。
![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240116211457.png)

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240116211633.png)
![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240116212301.png)

对于问题3：在图1是尝试新增节点S5，但是此时leader S3宕机，然后从s1,s2,s4中选举出了新leader,此时新增节点s6,新leader S1会应用配置$C_{new2}$，此时集群中只有S1S2S3S4S6五个节点。也就是S5没有成功添加进去。假设此时S1宕机，状态来到图4, S3由于是$C_{new_{1}}$的配置，它只需要得到S3、S4、S5三张选票即可当选leader。如果S3继续完成对$C_{new_{1}}$的配置（S3不知道S6已经加入了集群），那么就会最终导致S6没有被新加进来。
解决方法是：新leader必须提交一条自己任期内的no-op日志，才能开始单节点集群成员变更。

### RAFT日志压缩

本质上，是通过快照技术对当前的状态机的状态进行保存，然后把快照之前的日志删除即可。

**最新状态=快照+快照之后的日志**、

### 只读操作处理

只读操作要满足强一致性：读到的结果必须是已经提交了的结果。直接从leader上读可能不满足。例如：在leader和其他节点发生了网络分区情况下，其他节点可能已经重新选出了一个leader,而如果老leader在没有访问其他节点的情况下直接拿自身的值返回客户端，这个读取的结果就有可能不是最新的。
![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240116213738.png)
![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240116213859.png)
优化过后的线性一致性读，也至少需要一轮RPC(leader确认的心跳)。并不比写操作快多少(写操作最少也就一轮RPC)
如果对读不要求强一致性，那么：
![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240116214049.png)

### 性能

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240116214310.png)


## ParallelRaft

ParallelRaft是阿里云原生数据库PolarDB的底层文件PolarFS对Raft的一种优化的实现。
PolarFS:An Ultra-low Latency and Failure Resilient Distributed File System for Shared
Storage Cloud Database /VLDB 2018

### 问题
raft不允许日志空洞：日志只允许以固定的顺序串行复制、提交。
这就导致实际场景中大多数是并发场景，多个连接并发的向follower发送日志，只要一个连接有问题，就会导致整个日志乱掉，follower就会拒绝掉没有前序日志的日志，造成大量失败。

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240116215155.png)


## 强相关文献

| 名称 | 链接 | 说明 |
| ---- | ---- | ---- |
| 解读共识算法Raft（合集） | https://www.bilibili.com/video/BV1pr4y1b7H5/?spm_id_from=333.337.search-card.all.click&vd_source=47bbcc428387a807dfb9a0a62d6b09d1 |  |
