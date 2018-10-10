---
layout: post
title: Docker image build for cobar
date: 2018-10-10 15:32:24.000000000 +09:00
---

由于cobar的开源项目里没有提供Dockerfile，无法直接生成docker镜像，需要自己编写Dockerfile并build镜像。这里是将配置和cobar本身的jar及启动脚本打在一个镜像里。[项目路径](https://github.com/geksong/cobar-docker.git)

示例里将mysql和cobar都在同一个宿主机的不同container里，本机的```3307,3308,3309```三个端口分别对应于本机的三个mysql容器，实际存储的数据目录都在宿主机的```/dockerenv/cobarmysql/mysql/3307/data, /dockerenv/cobarmysql/mysql/3308/data/, /dockerenv/cobarmysql/mysql/3309/data/```，cobar container和mysql container位于同一个名为```private```的docker network。部署如下图：
![](/assets/images/docker-cobar/container-distribute.png)
三个mysql容器内的3306端口映射到宿主机的```3307,3308,3309```三个端口，cobar容器的```8066```端口则直接映射到宿主机的```8066```端口。

首先启动三个mysql的容器，这里使用5.7.23的mysql镜像，root的密码初始化为123456
```
docker run -d -p 3307:3306 -v ~/dockerenv/cobarmysql/mysql/3307/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=123456 --restart always --name cobar-mysql-3307 --network private mysql:5.7.23

docker run -d -p 3308:3306 -v ~/dockerenv/cobarmysql/mysql/3308/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=123456 --restart always --name cobar-mysql-3308 --network private mysql:5.7.23

docker run -d -p 3309:3306 -v ~/dockerenv/cobarmysql/mysql/3309/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=123456 --restart always --name cobar-mysql-3309 --network private mysql:5.7.23
```
执行上述命令之后，可以通过docker container查看下容器是否已正常启动
```
docker container ls -a | grep mysql
```
如果看到三个mysql的容器都是UP的状态，则说明mysql容器已经正常启动，接下来开始准备cobar的docker镜像。

* 本地创建一个cobar目录

```
mkdir cobar
cd cobar
```
* 从cobar的release目录下载稳定版，这里用```1.2.7```版本

```
wget https://github.com/alibaba/cobar/releases/download/v1.2.7/cobar-server-1.2.7.tar.gz
```
下载完成之后，执行解压
```
tar -xvzf cobar-server-1.2.7.tar.gz
```
解压之后会在当前目录生成```cobar-server-1.2.7```目录
其中```cobar-server-1.2.7/bin```是cobar的启停脚本，```cobar-server-1.2.7/conf```是cobar的配置文件，这里需要将conf里的```rule.xml,schema.xml,server.xml```三个文件拷贝到当前目录，然后修改其中的集群，用户名和密码等配置，docker打包镜像的时候，需要将这三个文件拷贝到镜像里，覆盖```cobar-server-1.2.7/conf```下的配置文件。
conf默认的配置里提供了一个dbtest的schema配置，这里示例基本不怎么修改，只修改```schema.xml```中的```<dataSource>```节点内容，因为其中配置了cobar代理的多个mysql节点的ip和端口，这里的ip需要换成docker容器网络内的ip，不能写127.0.0.1，因为cobar运行在容器里，127.0.0.1是他自己，并不是宿主机网络ip。mysql在容器网络内的ip可以通过```docker network inspect private | grep -A 5 mysql```查询到

```
<dataSource name="dsTest" type="mysql">
    <property name="location">
      <location>172.18.0.12:3307/dbtest</location>
      <location>172.18.0.13:3308/dbtest</location>
      <location>172.18.0.14:3309/dbtest</location>
    </property>
    <property name="user">root</property>
    <property name="password">123456</property>
    <property name="sqlMode">STRICT_TRANS_TABLES</property>
</dataSource>
```

* 编写cobar的Dockerfile

基础镜像使用openjdk:8，因为cobar本身需要java运行环境。容器内我们以```/usr/local/cobar```作为cobar的工作目录，注意一定要创建```/usr/local/cobar/logs```目录，因为cobar启动的时候写日志在这个目录，但是并不会自己生成logs目录。这里容器的启动入口，是一个自定义的```./bin/run.sh```，而不是cobar自带的```./bin/startup.sh```脚本，是因为cobar启动的时候不是一个交互式tty，docker会认为startup.sh执行完成后就结束了，容器会自动exit。```./bin/run.sh```在其中以```tail -f ```命令结束，维持了一个交互式命令，容器就不会自动退出
Dockerfile如下:
```
FROM openjdk:8
COPY ./cobar-server-1.2.7 /usr/local/cobar
COPY ./server.xml /usr/local/cobar/conf/server.xml
COPY ./scheme.xml /usr/local/cobar/conf/schema.xml
COPY ./rule.xml /usr/local/cobar/conf/rule.xml
COPY ./run.sh /usr/local/cobar/bin/run.sh
RUN mkdir -p /usr/local/cobar/logs
WORKDIR /usr/local/cobar
EXPOSE 8066
ENTRYPOINT exec /bin/sh ./bin/run.sh
```

run.sh如下:
```
touch file.log

/bin/sh ./bin/startup.sh

tail -f file.log
```

* 创建镜像

Dockerfile准备好之后，就行开始打包镜像了。在当前目录执行如下命令
```
docker build -t org.sixpence.cordock:0.0.1 .
```
输出
```
Sending build context to Docker daemon  3.206MB
Step 1/10 : FROM openjdk:8
 ---> 81f83aac57d6
Step 2/10 : COPY ./cobar-server-1.2.7 /usr/local/cobar
 ---> Using cache
 ---> 394f864871af
Step 3/10 : COPY ./server.xml /usr/local/cobar/conf/server.xml
 ---> Using cache
 ---> 182a4cf9b73f
Step 4/10 : COPY ./schema.xml /usr/local/cobar/conf/schema.xml
 ---> Using cache
 ---> 3ce43783b97a
Step 5/10 : COPY ./rule.xml /usr/local/cobar/conf/rule.xml
 ---> Using cache
 ---> 704b8eeb69ea
Step 6/10 : COPY ./run.sh /usr/local/cobar/bin/run.sh
 ---> Using cache
 ---> 100dc7313542
Step 7/10 : RUN mkdir -p /usr/local/cobar/logs
 ---> Using cache
 ---> a845b1563049
Step 8/10 : WORKDIR /usr/local/cobar
 ---> Using cache
 ---> 5982987498d0
Step 9/10 : EXPOSE 8066
 ---> Using cache
 ---> 19ee59d5f852
Step 10/10 : ENTRYPOINT exec /bin/sh ./bin/run.sh
 ---> Using cache
 ---> ffbacc43c43c
Successfully built ffbacc43c43c
Successfully tagged org.sixpence.cordock:0.0.1
```
则镜像打包完成，通过```docker images | grep cordock```可以看到本地的镜像仓库已经有刚打出来的镜像
```
org.sixpence.cordock                                                 0.0.1                                      ffbacc43c43c        8 hours ago         626MB
```

* 运行cobar容器

执行docker run命令则可以创建容器，并启动
```
docker run -d -p 8066:8066 -e TZ="Asia/Shanghai" --init --name cobar-default --network private org.sixpence.cordock:0.0.1
```
这里的```-e TZ="Asia/Shanghai"```用来指定容器的时区，否则时间会和国内时间不一致。```--init```显示指定容器启动完整的init system进程，这样我们的cobar进程就不会占用了1号进程。
执行完成之后，通过```docker container ls -a | grep cobar```能看到cobar容器状态是UP。

* client连接

  * 通过mysql客户端
  
  cobar本身是完全实现mysql的通讯协议的，所以基本上所有的mysql客户端都可以连接，只是有一些命令是禁止，比如join操作。其他的使用上基本上没差别
  
  * 通过java
  
  cobar官方提供了对应Driver，主要是2.0版本的driver提供了```cobar_cluster```的支持，如果需要使用```cobar_cluster```的高可用，则需要```server.xml```中配置```<cluster>```节点。否则会找不到cluster
