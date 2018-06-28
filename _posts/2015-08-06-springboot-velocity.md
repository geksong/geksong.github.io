---
layout: post
title: spring boot & velocity
date: 2015-08-06 15:32:24.000000000 +09:00
---

## maven版本
### pom.xml配置
spring boot web应用必须使用 ```spring-boot-starter-parent``` 作为父节点.
dependency 必须的有 ```spring-boot-starter-web``` , ```spring-boot-starter-velocity``` , ```spring-boot-starter-test```,```spring-boot-starter-actuator```,```junit```

大致的pom.xml文件内容为

```
  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>1.2.5.RELEASE</version>
  </parent>
  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-web</artifactId>
      <version>${spring.boot.version}</version>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-velocity</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-test</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
```

### spring boot 启动入口
spring boot 的启动入口是一个简单的main函数，类必须要```@SpringBootApplication```注解，在此入口处
可通过```@ImportResource```引入你自己的spring xml配置文件

```
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.ImportResource;

/**
 * spring boot 启动
 * Created by geksong on 15/8/4.
 */
@SpringBootApplication
@ImportResource(value = {"classpath:applicationContext-common.xml"})
public class Bootstrap {
    public static void main(String[] args) {
        ConfigurableApplicationContext configurableApplicationContext = SpringApplication.run(Bootstrap.class, args);
    }
}
```

### spring boot 配置
理论上说spring boot开箱即用，不需要配置。但实际生产环境中还是需要做配置的，比如单机要跑多实例，端口就需要改。
spring boot的配置文件默认都是在 ```src/main/resources/application.properties``` 文件中。
一些比较常用的配置如下

```
# EMBEDDED SERVER CONFIGURATION (ServerProperties)
server.port=8080

# HTTP encoding (HttpEncodingProperties)
# the encoding of HTTP requests/responses
spring.http.encoding.charset=UTF-8
# enable http encoding support
spring.http.encoding.enabled=true
# force the configured encoding
spring.http.encoding.force=true

# Velocity config
spring.velocity.content-type=text/html;charset=UTF-8
spring.velocity.dateToolAttribute=dateTool
spring.velocity.properties.input.encoding=UTF-8
spring.velocity.properties.output.encoding=UTF-8
```

还记得大明湖畔的 ```velocity.properties``` 吗～？现在不需要了，在 ```application.properties``` 文件中有
可设置的velocity配置。velocity乱码～？需要设置 ```input.encoding``` 和 ```output.encoding``` ，如上图
```spring.velocity``` 是前缀， ```properties``` 是键名，最终spring boot启动的时候会被包装成 ```VelocityProperties```
注入到 ```VelocityAutoConfiguration``` 中

### FAQ
#### 如何实现rest接口
spring boot 已经帮你配置好了spring mvc。实现rest有两种方式

1. @Controller + @ResponseBody
使用 ```@ResponseBody``` 注解的方法直接返回java pojo，spring mvc将包装为json返回
```
@Controller
public class Activity618 {

    @ResponseBody
    @RequestMapping("/finance/activity/findModel")
    public ActivityModel findModel() {
        Date date = HolidaysUtils.addWorkday(new Date(), 3);
        ActivityModel activityModel = new ActivityModel();
        activityModel.setAge(34);
        activityModel.setName("上来就撒娇");
        return activityModel;
    }
}
```

2. @RestController
```@RestController``` 实际上是 ```@Controller``` 和 ```@ResponseBody``` 包装的语法糖
使用此注解的controller，方法返回java pojo，即是rest接口
```
@RestController
public class Activity618 {

    @RequestMapping("/finance/activity/findModel")
    public ActivityModel findModel() {
        Date date = HolidaysUtils.addWorkday(new Date(), 3);
        ActivityModel activityModel = new ActivityModel();
        activityModel.setAge(34);
        activityModel.setName("上来就撒娇");
        return activityModel;
    }
}
```

#### 如何使用velocity模版渲染
spring boot 的velocity模版要求放在 ```src/main/resources/templates``` 目录下，spring boot的view名支持
此目录下的层级目录方式假如我有一个velocity文件是 ```src/main/resources/templates/index/index.vm``` 。则
此对应的view名是 ```index/index```
```
@Controller
public class Activity618 {

    @RequestMapping("/finance/activity/718")
    public String toIndex(Model model) {
        model.addAttribute("message", "是老骥伏枥时间");
        return "index/index";
    }

}
```

## gradle版本
### gradle 配置文件内容
```
group 'org.geksong'
version '1.0-SNAPSHOT'

buildscript {
    repositories {
        mavenCentral()
    }
    dependencies {
        classpath("org.springframework.boot:spring-boot-gradle-plugin:1.2.5.RELEASE")
    }
}
p
apply plugin: 'java'
apply plugin: 'scala'
apply plugin: 'spring-boot'
apply plugin: 'war'

jar {
    baseName = "play-framework-demo"
    version = "1.0-SNAPSHOT"
}

sourceCompatibility = 1.8
targetCompatibility = 1.8

repositories {
    mavenCentral()
}

dependencies {
    compile "org.springframework.boot:spring-boot-starter-web"
    compile "org.scala-lang:scala-library:2.11.6"
    compile "org.scala-lang:scala-compiler:2.11.6"
    compile "org.scala-lang:scala-reflect:2.11.6"
    compile "org.apache.httpcomponents:httpclient:4.3.6"
    compile "com.alibaba:fastjson:1.1.41"
    compile "org.slf4j:slf4j-api:1.7.5"
    compile "org.apache.commons:commons-lang3:3.2"
    compile "commons-httpclient:commons-httpclient:3.1"
    compile "org.apache.velocity:velocity:1.7"
    compile "org.apache.velocity:velocity-tools:2.0"
    compile "jstl:jstl:1.2"
    compile "org.apache.tomcat.embed:tomcat-embed-jasper"
    compile "org.springframework.boot:spring-boot-starter-velocity"
    testCompile group: 'junit', name: 'junit', version: '4.11'
}
```
