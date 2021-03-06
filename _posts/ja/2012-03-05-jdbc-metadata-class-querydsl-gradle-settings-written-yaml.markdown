---
date: 2012-03-05 12:45:55
lang: ja
layout: post
permalink: /archives/229
tags: [Java, Groovy, Gradle, Querydsl]
title: Make JDBC metadata class for Querydsl on Gradle with settings written by YAML
wordpress_id: 229
---
This is an example of build.gradle to make JDBC metadata class for Querydsl.
JDBC settings are written in ../config.yaml. The target RDBMS of JDBC is MySQL.
It's not smart, although it works well.

<pre class="prettyprint linenums lang-groovy">
// vim: set expandtab ts=2 sw=2 nowrap ft=groovy ff=unix : */
sourceCompatibility = 1.6 // TODO: 1.7
version = '1.0'
group = 'jp.co.wktk.apiserver'

apply plugin: 'java'
apply plugin: 'jetty'

jettyRun.contextPath = ''
jettyRunWar.contextPath = ''

task wrapper(type: Wrapper) {
  gradleVersion = '1.0-milestone-8a'
}

import groovy.sql.Sql
import com.mysema.query.sql.MetaDataExporter

sourceSets {
  main {
    java {
      srcDir getGeneratedSrcPath()
    }
  }
}

// This build script uses snakeyaml for load YAML settings about database for Querydsl.
import org.yaml.snakeyaml.Yaml
buildscript {
  repositories {
    mavenCentral()
  }
  dependencies {
    classpath group: 'org.yaml', name: 'snakeyaml', version: '1.10'
    classpath group: 'com.mysema.querydsl', name: 'querydsl-sql', version: '2.3.1'
  }
}

repositories {
  mavenCentral()
  maven {
    url 'http://source.mysema.com/maven2/releases/' // for Querydsl
  }
  maven {
    url 'http://mvnrepository.com/' // for MySQL
  }
}

configurations {
  mysqlDriver
}

dependencies {
  compile(
    // for querydsl
    [group: 'com.mysema.querydsl', name: 'querydsl-sql', version: '2.3.1'],
    [group: 'org.slf4j', name: 'slf4j-log4j12', version: '1.6.1'],
    // for yaml
    [group: 'org.yaml', name: 'snakeyaml', version: '1.10']
  )
  testCompile(
    [group: 'org.testng', name: 'testng', version: '6.4']
  )
  runtime(
    // for MySQL
    [group: 'mysql', name: 'mysql-connector-java', version: '5.1.18']
  )
  mysqlDriver group: 'mysql', name: 'mysql-connector-java', version: '5.1.18' // for MySQL
}

compileJava {
  doFirst {
    // load config from YAML
    File configFile = new File('../config.yaml')
    Yaml yaml = new Yaml();
    def config = yaml.load(configFile.newReader())
    def dbConfig = config.database;

    // Load MySQL Driver
    configurations.mysqlDriver.each {file ->
      gradle.class.classLoader.addURL(file.toURI().toURL())
    }

    // Create classes for Querydsl
    def sql = Sql.newInstance("jdbc:mysql://${dbConfig.host}:${dbConfig.port}/apiserver",
      dbConfig.username,
      dbConfig.password,
      'com.mysql.jdbc.Driver')
    MetaDataExporter exporter = new MetaDataExporter();
    exporter.setPackageName('jp.co.wktk.apiserver.persistence')
    exporter.setTargetFolder(getGeneratedSrcPath())
    exporter.export(sql.getConnection().getMetaData())
  }
}

test {
  useTestNG()
}

def getGeneratedSrcPath() {
  new File(
    buildDir.absolutePath + File.separator +
    'generated-src' + File.separator +
    'java')
}
</pre>
