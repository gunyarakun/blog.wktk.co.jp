---
layout: !binary |-
  cG9zdA==
status: !binary |-
  cHVibGlzaA==
published: true
title: Install &Oslash;MQ(zeromq) with libuuid from source code.
author: !binary |-
  dGFzdWt1
author_login: !binary |-
  dGFzdWt1
author_email: !binary |-
  YmxvZ0B3a3RrLmNvLmpw
wordpress_id: 108
wordpress_url: !binary |-
  aHR0cDovL2Jsb2cud2t0ay5jby5qcC8/cD0xMDg=
date: 2011-01-05 01:01:57.000000000 +09:00
categories:
- 技術メモ
- English
tags: []
comments: []
---
zeromq requires libuuid which is included in packages such as e2fsprogs-devel (RHEL/CentOS etc.) or libuuid-dev (Debian/Ubuntu).

e2fsprogs-devel contains not only libuuid but also many other libraries. If you need install ONLY libuuid from source code(and build zeromq with it), you should follow below.

<pre class="syntax bash-script">
PREFIX=/usr

# libuuid
tar xvfz e2fsprogs-1.41.12.tar.gz
cd e2fsprogs-1.41.12
./configure --enable-elf-shlibs --disable-testio-debug --disable-debugfs --disable-imager --disable-resizer
make
cp lib/libuuid*.a ${PREFIX}/lib
cp lib/libuuid*.so* ${PREFIX}/lib
cp lib/uuid/uuid.h ${PREFIX}/include/uuid
cp lib/uuid/uuid.pc ${PREFIX}/lib/pkgconfig
cd ..

# zeromq
tar xvfz zeromq-2.0.10.tar.gz
cd zeromq-2.0.10
CFLAGS="-I${PREFIX}/include" CXXFLAGS="-I${PREFIX}/include" LDFLAGS="-L${PREFIX}/lib" ./configure --prefix=${PREFIX}
make
make install
cd ..
</pre>
