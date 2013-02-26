---
layout: !binary |-
  cG9zdA==
status: !binary |-
  cHVibGlzaA==
published: true
title: Plack::Middleware::Image::DummyでCPAN authorデビュー!!
author: !binary |-
  dGFzdWt1
author_login: !binary |-
  dGFzdWt1
author_email: !binary |-
  YmxvZ0B3a3RrLmNvLmpw
wordpress_id: 309
wordpress_url: !binary |-
  aHR0cDovL2Jsb2cud2t0ay5jby5qcC8/cD0zMDk=
date: 2013-01-20 12:35:35.000000000 +09:00
categories:
- 技術メモ
- Perl
tags: []
comments: []
---
始めてのCPAN module、Plack::Middleware::Image::Dummyをshipitした。
<ul>
	<li><a href="http://search.cpan.org/~gunya/Plack-Middleware-Image-Dummy/">http://search.cpan.org/~gunya/Plack-Middleware-Image-Dummy/</a></li>
	<li><a href="https://github.com/gunyarakun/p5-Plack-Middleware-Image-Dummy">https://github.com/gunyarakun/p5-Plack-Middleware-Image-Dummy</a></li>
</ul>
約7年前に「<a href="http://d.hatena.ne.jp/tasukuchan/20060324/1143188619">本当のワタシ　デビュー！</a>」というCPAN authorになるぜエントリを書いていたのだが、やっとのデビュー。下積み長い！

Plack::Middleware::Image::Dummy は、<a href="http://dummyimage.com/">Dynamic Dummy Image Generator</a>のPlack版です。指定の幅・サイズ・ファイル形式の画像をURL1つで作ることができます。

たとえば、http://localhost:5000/400x300.pngというURLで、こんな画像が出てきます。

<img alt="" src="http://farm9.staticflickr.com/8215/8397330732_856bc6b262.jpg" width="400" height="300" />

画像内にあるテキスト、テキスト色、背景色も指定できます。
http://localhost:5000/200x300.png?text=美しすぎるカード画像&amp;color=ffffff&amp;bgcolor=000000
<img alt="" src="http://farm9.staticflickr.com/8374/8396246309_2c999fed4f.jpg" width="200" height="300" />

Imager::File::GIFを入れるときにhomebrewでgiflibを入れるんだけど、既存のヘッダとかと干渉してbrew linkがコケるのでbrew link -fでしのいだ。

Build.PLに必要なモジュールが足りずにバージョンアップしてしまったけど、
Module::BuildでREADME.podを賢く作る方法って何かないのかなー。
hirose31さんはシンボリックリンクを張っていて、単純明快でいいな、と思った。

こういったリリースしたぜブログエントリでなんでmetacpanのURLを貼るのか疑問だったんだけど、metacpanのほうが早く更新されるのね。
というわけで、こんな小品をリリースできていけたらいいな、と思っとる次第です。
<h2>追記</h2>
なんか今考えたらPlack::App::DummyImageとかのほうがいいんじゃね？と思ったりした。というわけで「Plack::App dummy」とCPANで検索してみたら、似たようなモジュールが上がっているという悲しい結末。せつないですね。先にモジュール見つけていたらこれ使っていたのに。TMTOWTDI!!!!

<a href="http://search.cpan.org/~bayashi/Plack-App-DummyBox/lib/Plack/App/DummyBox.pm">http://search.cpan.org/~bayashi/Plack-App-DummyBox/lib/Plack/App/DummyBox.pm

</a>
