---
layout: post
title: redis cluster
date: 2018-09-22 15:32:24.000000000 +09:00
---

## 简介
redis cluster是redis3.0版本官方退出的一种集群方案。目前redis的集群方案主要有三种方式。

* 一种是在客户端进行key分片。这种一般都是基于一致性hash算法实现，如果集群要扩容必须要手动操作，且无法对客户端透明，因为客户端必须要跟集群里所有的节点进行连接
* 第二种是代理分片，即把第一种种的分片事情交由一个中间代理去专职处理，比如codis,twemproxy，代理负责命令转发，命令的执行路径基本上是client->proxy->redisserver的过程。这种方式
能把分片对客户端完全透明，且能够完全跟redis本身的通讯协议保持一致，扩容，缩容，故障转移都只会集中在运维层，客户端无需感知
* 第三种是在redisserver负责分片。这种集群里每个master节点都负责维护一部分的hash slots，所有的节点之间通过p2p协议进行自身状态的广播，以达到最终在某个时间点能够达到全局的数据一致性。
所以这种方式具有天然的去中心化性，集群扩容对于客户端也是透明的，通过多数派的投票能在某个master节点down机之后，多数的master能从down机的master节点的slave节点中选举出替代节点，从而实现自动故障转移

redis cluster正是这第三种方式的实现，redis cluster总共提供了16384个hash slots，集群中的所有master节点各自负责其中的一部分slots，集群中每个节点都会和其他的节点通讯，所以任何一个节点都会知道其他
所有节点的状态，这也是redis cluster能够自动实现故障转移的基础。

## 搭建一个redis cluster
要建立一个redis cluster集群，集群内的所有节点都需要以cluster模式运行，这可以在每个节点的redis.conf中进行配置。这里我总共配置了6个节点，分别是本地的```7000,7001,7002,7100,7101,7102```六个端口，
其中的70xx端口的节点将作为master节点，而71xx端口的节点将作为slave节点。每个节点的redis.conf配置都如下，只是端口不同
```
port 7000
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
appendonly yes
```
这里为了方便，直接使用docker容器来启动redis，启动的命令也基本相同，只是端口的区别
```
docker run -d -p 7000:7000 --name redis-cluster-m7000 --network private -v /Users/geksong/Documents/share/redis/cluster/7000/redis.conf:/usr/local/etc/redis/redis.conf redis:latest redis-server /usr/local/etc/redis/redis.conf
```

当按如上方式处理之后，其实这六个节点还没有构建成一个集群，而是六个节点在各自的集群里，相互之间互不相认，基本是下面这个状态
![](/assets/images/redis-cluster/cluster-node-init.png)

要让这六个节点能到一个集群里，需要通过```cluster meet```，让节点和集群内容的任意一个节点完成握手，如下
```
cluster meet 172.18.0.9 7100
+OK
```
cluster meet握手的过程就类似tcp的握手，只是其中的meet和pong消息，发送方都会带上自己的信息，以让对手方将自己的信息记录到对手方的数据结构里。如下
![](/assets/images/redis-cluster/cluster-node-handshake.png)

当所有的节点经过握手之后，此时六个节点就在一个集群里，这时通过```cluster nodes```能够查看到这个集群里总共有多少个节点。如下
```
cluster nodes
e638732a15e2504086315073353807a114ea6c6e 172.18.0.11:7102@17102 master - 0 1537414196548 0 connected
cd0de5cabd77e2fc0a09fa27fb347d84c2b660f4 172.18.0.7:7001@17001 myself,master - 0 1537414196000 5 connected
a6fec01802860834b1f8341617cf1d0ea9b35fee 172.18.0.8:7002@17002 master - 0 1537414195000 2 connected
7dc58e6dabe06ea201b366087626a86ce835f96b 172.18.0.9:7100@17100 master - 0 1537414195544 3 connected
409d3572f9e6e8f6c1d63f582b7adbb5dc852097 172.18.0.10:7101@17101 master - 0 1537414195043 4 connected
```
但此时从输出中能看到所有的节点的角色都是master，是因为还没有分配master和slave的关系，这时通过```cluster replicate```可以将当前的节点配置为目标节点的slave。如下
```
cluster replicate 21d776ddfcc26c61ff8d81ec9ad023b1812cb32d
+OK
```
当通过replicate分配了master和slave的关系之后，可以从cluster nodes的输出看到master和slave的关系。
```
cluster nodes
$741
409d3572f9e6e8f6c1d63f582b7adbb5dc852097 172.18.0.10:7101@17101 slave cd0de5cabd77e2fc0a09fa27fb347d84c2b660f4 0 1537538414197 5 connected
cd0de5cabd77e2fc0a09fa27fb347d84c2b660f4 172.18.0.7:7001@17001 master - 0 1537538413089 5 connected 5001-16383
a6fec01802860834b1f8341617cf1d0ea9b35fee 172.18.0.8:7002@17002 master - 0 1537538414197 2 connected
21d776ddfcc26c61ff8d81ec9ad023b1812cb32d 172.18.0.6:7000@17000 myself,master - 0 1537538413000 1 connected 0-5000
7dc58e6dabe06ea201b366087626a86ce835f96b 172.18.0.9:7100@17100 slave 21d776ddfcc26c61ff8d81ec9ad023b1812cb32d 0 1537538413189 3 connected
e638732a15e2504086315073353807a114ea6c6e 172.18.0.11:7102@17102 slave a6fec01802860834b1f8341617cf1d0ea9b35fee 0 1537538413000 2 connected
```
此时整个集群如下
![](/assets/images/redis-cluster/cluster-all.png)

经历了节点间握手，主从配置是否当前的集群就ok了，其实不然，此时集群还是处于下线状态，当尝试执行redis的读写命令的时候，会抛出错误。如下
```
set dddd tt
-CLUSTERDOWN Hash slot not served

```
从错误返回中能看到是因为这个集群里的hash slots还没有分配，所以所有的master节点都不知道自己应该处理哪些hash slots。redis cluster提供了```cluster addslots```命令来为节点分配
服务的hash slots。但是只能具体的每个slot去加，所以这里写了个脚本去处理这个事情
```
slots=""

for(( ind = $4; ind <= $5; ind++ ))
do
    slots=${slots}" "${ind}
done

(
    echo cluster $3 ${slots};
    sleep 10;
    echo quit;
) | telnet $1 $2
```
将此内容保存到一个sh文件中即可，分配slots时，只需要像如下的方式执行
```
./cluster-slots.sh 127.0.0.1 7000 addslots 0 5000
```
即可将0到5000范围的所有hash slots分配给```127.0.0.1 7000```这个节点及它的所有slave节点

当所有16384个hash slots都分配完成之后，此时再通过```cluster info```命令则可看到集群是可用状态，且发送redis命令给任意节点，都不会再报错了。
```
cluster info
$519
cluster_state:ok
cluster_slots_assigned:16384
cluster_slots_ok:16384
cluster_slots_pfail:0
cluster_slots_fail:0
cluster_known_nodes:6
cluster_size:2
cluster_current_epoch:5
cluster_my_epoch:1
cluster_stats_messages_ping_sent:16142
cluster_stats_messages_pong_sent:16116
cluster_stats_messages_meet_sent:4
cluster_stats_messages_sent:32262
cluster_stats_messages_ping_received:16114
cluster_stats_messages_pong_received:16146
cluster_stats_messages_meet_received:2
cluster_stats_messages_received:32262
```

## 命令执行过程
当向redis cluster中的某个master节点发送一个redis 命令的时候，master收到这个命令，会对key进行crc16的算法得到一个整数，然后将此整数对16384进行取模运算，结果就是这个key所对应的hash slot，
如果该slot属于当前master所负责的范围，则会执行对应的命令处理器执行。否则将返回```+MOVED```，返回值中将带有slot所在的节点的ip和port。客户端需要重新将命令发送给对应ip:port。
![](/assets/images/redis-cluster/cluster-commond-exe.png)

这里节点是如何快速区分出key是否应该是自己服务，并且在不是自己的服务范围的时候能准确的返回给客户端slot对应的节点的ip和port呢？这个跟redis cluster内部存储集群状态的数据结构有关，如下图
![](/assets/images/redis-cluster/cluster-data-struct.png)
其中的clusterState记录了当前集群的一个配置纪元，以及一个16384长度的clasterNode指针数组，这里数组的每个index对应的就是hash slot，当数组中的某一个index为null，则表示当前集群里没有处理这个
slot的节点，集群不可服务。同理，当需要寻找一个hash slot应该是哪个节点负责处理时，只需要直接通过数组的index取值即可，O(1)的常量时间复杂度。而当需要知道当前节点应该处理哪些hash slots时，则是
在clusterNode里有一个16384/8长度的long数组，这个数组里每个值都是8位二进制，每个二进制位代表了对应的slot，值只有0和1，如果是0，则表示当前这个二进制位对应的slot不属于当前节点，否则则属于，同样也是O(1)时间复杂度就能确定一个slot是否应该是当前节点负责。

## HA
### 复制
redis的复制有两种 SYNC和PSYNC(redis2.8版本之后才有)
当一个slave节点首次和master连接的时候，slave会发送sync命令，以要求全量复制，此时master将在后台fork子进程，执行dump，将当前的数据写入rdb文件，并且将后续接收到的命令写入到缓冲区，当dump完成之后，master会向slave发送ping命令确认连接可用性，然后将文件内容发送到slave，slave接收rdb，并将rdb文件进行加载，然后master通过命令传播的方式将从dump的时候接收到命令发送给slave，slave依次执行命令。在2.8版本之前，redis的slave如果有任何时候依次闪断，都需要重新到master节点进行全量同步，这样对于整个集群的带宽是一个非常大的负担。所以在2.8版本开始提供了另一种复制方式PSYNC，也就是增量复制，PSYNC这种方式，在master节点上维护了一个复制积压缓冲区，这是一个固定长度的连续区域，默认是1M，以及当前master的最大偏移(```master_repl_offset```)缓冲区中实际的数据长度(```repl_backlog_histlen```)。而slave需要记录的则是复制的master的runid和复制的最新偏移。当slave需要执行pysnc的时候，需要带上之前复制的runid以及复制的最新偏移，master在收到这个命令的时候，会做如下判断：

谈到高可用围绕几个问题
1. 集群里master节点可以挂几个
2. slave如果断线重连会不会丢数据
3. master切换的时候能提供服务吗，数据会不会丢
