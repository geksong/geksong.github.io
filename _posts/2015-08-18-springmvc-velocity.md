---
layout: post
title: spring mvc & velocity
date: 2015-08-21 15:32:24.000000000 +09:00
---

## pom.xml
```
<?xml version="1.0"?>
<project
        xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd"
        xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <modelVersion>4.0.0</modelVersion>
  <groupId>org.geksong.finance</groupId>
  <artifactId>finance-activity-web</artifactId>
  <packaging>war</packaging>
  <version>1.0-SNAPSHOT</version>
  <name>finance-activity-web Maven Webapp</name>
  <url>http://maven.apache.org</url>
  <properties>
    <spring.boot.version>1.2.5.RELEASE</spring.boot.version>
  </properties>
  <dependencies>
    <dependency>
      <groupId>org.springframework</groupId>
      <artifactId>spring-webmvc</artifactId>
      <version>4.2.0.RELEASE</version>
    </dependency>
    <dependency>
      <groupId>commons-fileupload</groupId>
      <artifactId>commons-fileupload</artifactId>
      <version>1.3.1</version>
    </dependency>
    <dependency>
      <groupId>org.springframework</groupId>
      <artifactId>spring-test</artifactId>
      <version>4.2.0.RELEASE</version>
    </dependency>
    <dependency>
      <groupId>com.fasterxml.jackson.core</groupId>
      <artifactId>jackson-databind</artifactId>
      <version>2.6.0</version>
    </dependency>
    <dependency>
      <groupId>net.sf.json-lib</groupId>
      <artifactId>json-lib</artifactId>
      <version>2.4</version>
      <classifier>jdk15</classifier>
    </dependency>
    <dependency>
      <groupId>com.alibaba</groupId>
      <artifactId>fastjson</artifactId>
      <version>1.2.6</version>
    </dependency>
    <dependency>
      <groupId>ch.qos.logback</groupId>
      <artifactId>logback-classic</artifactId>
      <version>1.1.3</version>
    </dependency>
    <dependency>
      <groupId>org.slf4j</groupId>
      <artifactId>log4j-over-slf4j</artifactId>
      <version>1.7.7</version>
    </dependency>
    <dependency>
      <groupId>javax.servlet</groupId>
      <artifactId>javax.servlet-api</artifactId>
      <version>3.1.0</version>
      <scope>provided</scope>
    </dependency>
    <dependency>
      <groupId>junit</groupId>
      <artifactId>junit</artifactId>
      <version>4.11</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>com.googlecode.xmemcached</groupId>
      <artifactId>xmemcached</artifactId>
      <version>2.0.0</version>
    </dependency>
    <dependency>
      <groupId>jedis</groupId>
      <artifactId>jedis</artifactId>
      <version>2.1.0</version>
    </dependency>
    <dependency>
      <groupId>commons-pool</groupId>
      <artifactId>commons-pool</artifactId>
      <version>1.5.5</version>
    </dependency>
    <dependency>
      <groupId>org.apache.commons</groupId>
      <artifactId>commons-lang3</artifactId>
      <version>3.2</version>
    </dependency>
  </dependencies>
  <build>
    <finalName>finance-activity-web</finalName>
    <plugins>
      <plugin>
        <groupId>org.apache.tomcat.maven</groupId>
        <artifactId>tomcat7-maven-plugin</artifactId>
        <version>2.2</version>
        <configuration>
          <port>8081</port>
          <path>/</path>
        </configuration>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>2.1.2</version>
        <configuration>
          <testFailureIgnore>true</testFailureIgnore>
          <!--skipTests>true</skipTests -->
          <includes>
            <include>**/*Test.java</include>
          </includes>
          <argLine>-Xmx1024m</argLine>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
```

## ```resources/servlet-context.xml```
```
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xmlns:mvc="http://www.springframework.org/schema/mvc"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-3.1.xsd
		http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context-3.1.xsd
		http://www.springframework.org/schema/mvc http://www.springframework.org/schema/mvc/spring-mvc-3.1.xsd">

    <bean class="org.springframework.beans.factory.config.PropertyPlaceholderConfigurer">
        <property name="locations">
            <list>
                <value>file:${app.properties.file}</value>
            </list>
        </property>
    </bean>

    <context:component-scan base-package="org.geksong.finance.activity"/>

    <!-- 拦截器堆栈	-->
    <mvc:annotation-driven/>
    <!--<mvc:interceptors>
        <mvc:interceptor>
            <mvc:mapping path="/front/**"/>
            <ref bean="frontLoginInterceptor"/>
        </mvc:interceptor>
    </mvc:interceptors>-->

    <!--<bean class="org.springframework.web.servlet.view.BeanNameViewResolver">
        <property name="order" value="1" />
    </bean>-->

    <!--<bean name="jsonView"
          class="org.springframework.web.servlet.view.json.MappingJackson2JsonView">
    </bean>-->

    <bean class="org.springframework.web.servlet.view.InternalResourceViewResolver">
        <property name="prefix" value="/"/>
        <property name="suffix" value=".jsp"/>
    </bean>

    <bean id="multipartResolver"
          class="org.springframework.web.multipart.commons.CommonsMultipartResolver">
        <!-- one of the properties available; the maximum file size in bytes 2M
        <property name="maxUploadSize" value="2097152" />
        -->
    </bean>
    <!-- 上传文件异常配置
    <bean id="exceptionResolver" class="org.springframework.web.servlet.handler.SimpleMappingExceptionResolver">
        <property name="exceptionMappings">
            <props>
                <prop key="java.lang.Exception">
                    fileupload_error
                </prop>
            </props>
        </property>
    </bean>
    -->

</beans>
```

## ```resources/logback.xml```
```
<?xml version="1.0" encoding="UTF-8" ?>
<configuration scan="true">
    <Property name="LOG_HOME" value="${logback.home}"/>
    <!-- 控制台输出 -->
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <filter class="ch.qos.logback.classic.filter.ThresholdFilter">
            <level>info</level>
        </filter>
        <encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
            <!--格式化输出：%d表示日期，%thread表示线程名，%-5level：级别从左显示5个字符宽度%msg：日志消息，%n是换行符 -->
            <!--<pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} %-4relative [%thread] %-5level %class - %msg%n</pattern>-->
            <pattern>%date{ISO8601} %-5level [%thread] %logger{32} - %message%n</pattern>
        </encoder>
    </appender>
    <root level="debug">
        <appender-ref ref="STDOUT"/>
    </root>

</configuration>
```


## ```resources/applicationContext-common.xml```

```
<?xml version="1.0" encoding="UTF-8"?>

<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:aop="http://www.springframework.org/schema/aop"
       xmlns:tx="http://www.springframework.org/schema/tx" xmlns:jdbc="http://www.springframework.org/schema/jdbc"
       xmlns:context="http://www.springframework.org/schema/context"
       xmlns:task="http://www.springframework.org/schema/task"
       xmlns:dubbo="http://code.alibabatech.com/schema/dubbo"
       xsi:schemaLocation="
     http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context-3.0.xsd
     http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-3.0.xsd
     http://www.springframework.org/schema/jdbc http://www.springframework.org/schema/jdbc/spring-jdbc-3.0.xsd
     http://www.springframework.org/schema/tx http://www.springframework.org/schema/tx/spring-tx-3.0.xsd
     http://www.springframework.org/schema/aop http://www.springframework.org/schema/aop/spring-aop-3.0.xsd
     http://www.springframework.org/schema/task http://www.springframework.org/schema/task/spring-task-3.0.xsd
       http://code.alibabatech.com/schema/dubbo http://code.alibabatech.com/schema/dubbo/dubbo.xsd"
       default-autowire="byName">

    <context:annotation-config />
    <task:annotation-driven executor="myExecutor"/>
    <task:executor id="myExecutor" pool-size="5"/>
    <!-- ##############以下内容无需修改,也无需关心################# -->
    <!-- =========用户可定义属性配置文件=========== -->
    <bean id="propertyConfigurer"
          class="org.springframework.beans.factory.config.PropertyPlaceholderConfigurer">
        <property name="ignoreUnresolvablePlaceholders" value="true" />
        <property name="locations">
            <list>
                <value>file:${app.properties.file}</value>
            </list>
        </property>
        <property name="order" value="1" />
    </bean>

</beans>
```

## ```webapp/WEB-INF/web.xml```

```
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://java.sun.com/xml/ns/javaee" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://java.sun.com/xml/ns/javaee http://java.sun.com/xml/ns/javaee/web-app_2_5.xsd"
         version="2.5">
    <display-name>fc activity front</display-name>

    <!-- spring 初始化 -->
    <context-param>
        <param-name>contextConfigLocation</param-name>
        <param-value>classpath:applicationContext-common.xml</param-value>
    </context-param>
    <listener>
        <listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
    </listener>

    <filter>
        <filter-name>encoding filter</filter-name>
        <filter-class>org.springframework.web.filter.CharacterEncodingFilter</filter-class>
        <init-param>
            <param-name>forceEncoding</param-name>
            <param-value>true</param-value>
        </init-param>
        <init-param>
            <param-name>encoding</param-name>
            <param-value>UTF-8</param-value>
        </init-param>
    </filter>
    <filter-mapping>
        <filter-name>encoding filter</filter-name>
        <url-pattern>/*</url-pattern>
    </filter-mapping>
    <servlet>
        <servlet-name>SpringMVC</servlet-name>
        <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
        <init-param>
            <param-name>contextConfigLocation</param-name>
            <param-value>classpath:servlet-context.xml</param-value>
        </init-param>
        <load-on-startup>1</load-on-startup>
    </servlet>
    <servlet-mapping>
        <servlet-name>SpringMVC</servlet-name>
        <url-pattern>*.do</url-pattern>
    </servlet-mapping>
</web-app>
```

## ```controller```

```
@Controller
public class Activity618 {
    @Autowired
    private P2pBasicInformationService p2pBasicInformationService;
    @RequestMapping("/finance/activity/618")
    public String welcome(Map<String, Object> model) {
        model.put("time", new Date());
        model.put("message", "hello");
        return "welcome";
    }

    @RequestMapping("/finance/activity/718")
    public String toIndex(Model model) {
        P2pBasicInformation p2pBasicInformation = p2pBasicInformationService.getP2pBasicInfomation("10000027");
        model.addAttribute("message", "是老骥伏枥时间");
        return "index/index";
    }

    @ResponseBody
    @RequestMapping("/finance/activity/findModel")
    public ActivityModel findModel() {
        ActivityModel activityModel = new ActivityModel();
        activityModel.setAge(34);
        activityModel.setName("上来就撒娇");
        return activityModel;
    }
}
```

## FAQ
1. 如何使用单元测试跑web的测试
测试web url可使用spring mvc 提供的test模块，其中包含了request和response的mock

```
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.JUnitCore;
import org.junit.runner.RunWith;
import org.junit.runners.JUnit4;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;
import org.springframework.test.context.web.WebAppConfiguration;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.setup.MockMvcBuilders.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import org.springframework.test.web.servlet.MvcResult;
import org.springframework.web.context.WebApplicationContext;

/**
 * Created by geksong on 15/8/5.
 */
@RunWith(SpringJUnit4ClassRunner.class)
@WebAppConfiguration
@ContextConfiguration(locations = {"classpath:applicationContext-common.xml", "classpath:servlet-context.xml"})
public class Activity618Test {
    @Autowired
    private WebApplicationContext wac;

    private MockMvc mockMvc;

    @Before
    public void setup() {
        this.mockMvc = webAppContextSetup(this.wac).build();
    }

    @Test
    public void testToIndex() throws Exception{
        MvcResult result = this.mockMvc.perform(get("/finance/activity/findModel"))
                .andExpect(status().isOk()).andReturn();
    }
}
```

2. 如何跑此项目
可借助于maven提供的tomcat plugin。 =mvn tomcat7:run= 即可启动此web工程
