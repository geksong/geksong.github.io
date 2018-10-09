---
layout: post
title: disruptor
date: 2018-09-18 15:32:24.000000000 +09:00
---

disruptor 是LMAX公司开源的无锁队列库。和java的阻塞队列很像，设计的初衷都是为了在线程间传输消息或事件。但disruptor有一些独有的特性

1. 支持事件广播给所有消费者
2. 事件内存预分配
3. 无锁

## 组件
### Ring Buffer
Ring buffer是个环形队列，在disruptor中负责存储和更新传输的Event

### Sequence
Sequence被用来标注disruptor中其他组件在ringbuffer中操作的位置。每个consumer(EventProcessor)和disruptor自身都会持有一个Sequence，绝大多数的并发操作都依赖于对Sequence的更新操作，因此Sequence和AtomicLong一样支持大多数的线程安全操作，但Sequence比AtomicLong提供的一个优化是避免了[伪共享问题](http://ifeve.com/falsesharing/)

![](/assets/images/disruptor-arch.png)

### ByteBuffer
1. 缓冲区 
2. 可分配jvm内存也可以直接分配操作系统内存
3. 可切换读和写模式
