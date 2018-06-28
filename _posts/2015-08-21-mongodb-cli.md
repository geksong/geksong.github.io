---
layout: post
title: mongodb cli 简单使用
date: 2015-08-21 15:32:24.000000000 +09:00
---


## 连接远程主机
```
mongo -u uname -p pwd ip:port/dbname
```

## 批量执行命令
mongodb client 可执行js脚本，但js里不是简单的mongo命令堆积。借用mongo的jsapi查询
或更新数据，脚本如下:
```
var cursor = db.activationSource.find({"$and":[{"source":4},{"idfa":{"$in":['6E45C0AE-89BA-4AFF-BC60-27059042EA65','5B2059B8-7E52-444C-A222-51DBB02D7EE0']}}]}, {"callbackUrl":1});
print(cursor.size());
while(cursor.hasNext()) {
        var tmp = cursor.next();
        print(tmp.callbackUrl);
}
```
mongo 执行此js，通过shell命令可写入到文件
```
mongo -u uname -p pwd ip:port/dbname queryCallback.js > querycall.txt
```
