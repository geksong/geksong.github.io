---
layout: post
title: Google jib镜像打包试水
date: 2018-07-20 15:32:24.000000000 +09:00
---

## 介绍

Jib是google开源的镜像构建工具，提供以maven plugin的方式实现应用打包成docker的镜像。最主要的目标是将dockerfile，docker build，docker push这样偏发布运维层面的事情对开发者屏蔽，想想一个应用开发者当需要创建一个应用生成镜像时要写一个复杂的Dockerfile，是何其痛苦的事情。jib则帮做了这件事情，使得应用开发不再需要关注镜像打包的细节，集成在mvn package阶段，coder just coding。Jib的打包是docker 镜像中的层的更新，打包更快，没有改变的层不会重复打包。一个基础工具能达到提高coder的开发效率，帮助coder聚焦在自己擅长的领域就是一个完美的基础工具。

官方文档说的目标

* 更快 - 能更快的发布更新。Jib将应用拆分成多个层，从类里拆分依赖，使得有更新时不再需要Docker完全重新打包

* 可覆盖更新 - 重新打包没有变更的应用时总是同一个镜像。节省不必要的重复更新。

* 减少命令操作 - 减少在打镜像过程中的命令行操作。直接使用maven或gradle实现编译打包push到远程镜像仓库。再也不需要写Dockerfile然后调用docker build/push

## 示例

本例使用Jib打包一个jibdemo的latest镜像并推送到本地的docker registry [源码](https://github.com/geksong/jibdemo)
因为实际都是maven的plugin跑，所以这里直接先贴```pom.xml```

```
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>

	<groupId>org.sixpence</groupId>
	<artifactId>jibdemo</artifactId>
	<version>0.0.1-SNAPSHOT</version>

	<packaging>jar</packaging>

	<name>jibdemo</name>
	<description>jibdemo</description>

	<properties>
		<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
		<project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
		<java.version>1.8</java.version>
		<jib-maven-plugin.version>0.9.6</jib-maven-plugin.version>
	</properties>

	<dependencies>

	</dependencies>

	<build>
		<plugins>
			<plugin>
				<groupId>org.apache.maven.plugins</groupId>
				<artifactId>maven-compiler-plugin</artifactId>
				<configuration>
					<source>1.8</source>
					<target>1.8</target>
				</configuration>
			</plugin>

			<!-- Jib -->
			<plugin>
				<groupId>com.google.cloud.tools</groupId>
				<artifactId>jib-maven-plugin</artifactId>
				<version>${jib-maven-plugin.version}</version>
				<configuration>
					<allowInsecureRegistries>true</allowInsecureRegistries>
					<from>
						<image>openjdk:8-jre-alpine</image>
						<credHelper>osxkeychain</credHelper>
					</from>
					<to>
						<image>localhost:5000/jibdemo:latest</image>
						<credHelper>osxkeychain</credHelper>
					</to>
					<container>
						<mainClass>org.sixpence.jibdemo.BootStrapApplication</mainClass>
					</container>
				</configuration>
				<executions>
					<execution>
						<phase>package</phase>
						<goals>
							<goal>build</goal>
						</goals>
					</execution>
				</executions>
			</plugin>
		</plugins>
	</build>

</project>

```

主要关注```plugins/plugin/```，需要引用jib plugin，即
```
<groupId>com.google.cloud.tools</groupId>
<artifactId>jib-maven-plugin</artifactId>
```

```configuration```主要是对镜像打包过程使用到的配置(0.9.x版本的配置和0.1.x版本的配置标签名不同，本例使用是0.9.6版本的Jib)，Jib支持的配置如下:

|标签名|值类型|默认值|说明|
|---|---|---|---|
|from|含子属性|参见from子属性|配置该应用打包所使用的基础镜像名|
|to|含子属性|没有默认值，这个标签必须要显示写明|配置该应用最终打包成的镜像名|
|container|含子属性|参见container子属性|配置镜像的container|
|useOnlyProjectCache|boolean|false|配置cache的范围，如果设置为true，jib在不同的gradle项目间共享缓存|
|allowInsecureRegistries|boolean|false|这个值如果设置为true，Jib会用http作为https的fallback策略，当https请求不通时，会使用http请求|

```from```的子属性

|属性名|类型|默认值|说明|
|---|---|---|---|
|image|string|```gcr.io/distroless/java```|基础镜像|
|credHelper|string|无|docker pull验证证书类型的后缀名|

```container```的子属性

|属性名|类型|默认值|说明|
|---|---|---|---|
|jvmFlags|list|无|容器内jvm启动时的环境变量|
|mainClass|String|支持推导|容器的entrypoint的主类|
|args|list|无|启动主类时main方法的入参|
|ports|list|无|运行时容器对外暴露的端口|
|format|string|Docker|镜像的类型，jib还支持OCI镜像|
|useCurrentTimestamp|boolean|false|默认时，Jib会抹掉所有时间戳以保证镜像的可再现性，如果此值被设置为true，Jib会把镜像的创建时间标记为镜像的构建时间，这样牺牲了可再现性来方便可以轻松的判断镜像是什么时候创建的|

执行```mvn package```则可以对当前应用打包，Jib会将镜像推送```to```标签指定的镜像地址上。
