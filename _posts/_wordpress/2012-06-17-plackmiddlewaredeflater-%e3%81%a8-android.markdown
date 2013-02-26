---
layout: !binary |-
  cG9zdA==
status: !binary |-
  cHVibGlzaA==
published: true
title: Plack::Middleware::DeflaterとAndroidブラウザとの食い合せがよくない件
author: !binary |-
  dGFzdWt1
author_login: !binary |-
  dGFzdWt1
author_email: !binary |-
  YmxvZ0B3a3RrLmNvLmpw
wordpress_id: 244
wordpress_url: !binary |-
  aHR0cDovL2Jsb2cud2t0ay5jby5qcC8/cD0yNDQ=
date: 2012-06-17 19:27:14.000000000 +09:00
categories:
- Perl
tags: []
comments: []
---
下記の問題は、Plack::Middleware::Deflater 0.08で修正されました。kazeburoさん、ありがとうございます！

<del>Plack::Middleware::Deflaterで、Androidブラウザでだけ表示がされなかったり、コンテンツが途中で切れてしまう不具合に悩んでいる(Android 2.3.3 simulator, 2.3.4実機で確認)。</del>PCブラウザ、iPhoneだとOK。

再現手順は以下のとおりだけど、なんでじゃろ。解析のためにAndroidをビルドするのもなー。
<pre class="syntax perl">#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Plack::Builder;
use Plack::Request;

builder {
  enable "Deflater",
    content_type => ['text/html'],
    vary_user_agent => 1;
  sub {
    my $env = shift;
    return [200, ['Content-Type' => 'text/html'],
      ['<html><head><title>Android Error</title></head><body>This text cannot be shown in Android</body></html>']];
  }
};</pre>
