---
layout: !binary |-
  cG9zdA==
status: !binary |-
  cHVibGlzaA==
published: true
title: Scala + MongoDB + Herokuで2chクローンを作る（連載第１回）
author: !binary |-
  dGFzdWt1
author_login: !binary |-
  dGFzdWt1
author_email: !binary |-
  YmxvZ0B3a3RrLmNvLmpw
wordpress_id: 214
wordpress_url: !binary |-
  aHR0cDovL2Jsb2cud2t0ay5jby5qcC8/cD0yMTQ=
date: 2011-10-17 20:18:08.000000000 +09:00
categories:
- Scala
- MongoDB
- 2chクローン
tags: []
comments: []
---
人生で3回2chクローン掲示板システムをプログラムし、運用したことがある。

まずはじめは、C++。boostを使ってテンプレート満載な構成だった。VC6でコンパイルできないパターンがあって泣いたっけ。コンパイルの「遅さ」にほくそ笑んでた。あの頃は若かった。

そのコードを使って東京工業大学掲示板というWeb掲示板システムを運用していた。C++では機動的な新機能開発が難しいことを、すぐに思い知った。当時使ったことがなかったPHPで試しにリライトしてみた。数時間で開発できちゃった。すぐリプレイスしちゃうよね。

ニコニコ大百科というWikiシステムを書いたときにも、付随する2ch式の掲示板システムを書いた。Rubyだった。Rubyで実用的なWebアプリケーションを書いたことがなかったが、これも難なく実装することができた。UTF-8を採用したので、トリップの互換性を取るのが面倒だった。

PythonではDjango/Kayそれぞれで掲示板が読み書きレベルでいるくらいまで書いたが、サービスインすることはなかった。

先日、@bibrostさんとお会いする機会があり、ScalaとMongoDBのよさを熱弁されていた。さらに、GraphDBの勉強会でも再度お会いし、これは運命(!?)というしかない状態。さらに、Python Dev. festaで、@voluntasさんがHerokuの話をしていて、そいえば使ったことないなー、と思った。

ピコーン！これらを組み合わせて、2chクローン作ってみて勉強すればよくね？俺の技術catch upは2chクローンを書くことから始まる、的な。

というわけで実録「新しいミドルウェア使うときは大体こんな感じでやるよね」的なエントリを連載します。

Scala始めるならまずこれ、コップ本を読みだした。最近技術書を通しで読めなくなっている僕にとってはキツい厚さ。とりあえず14章まで目を通す。また後で続き読む。

本を読み過ぎたので、浮気してどんなフレームワークを使うかをWeb検索をして考える。ScalaのWebフレームワークは、LiftとPlay! frameworkが著名か。UnfilteredとかScalatraもあるか。

ここで一考。サーバはデータだけを返して、各種レンダリングはクライアントでやらせよう。ほら今時はスマホアプリの時代ですよ。サーバはデータだけ返して、クライアントでレンダリングですよ。SEO的には悪そうだけど、まあスケールはしそうだよね。そういう観点だと、Webフレームワークは使う必要はないか。そしたら、Twitterのfinagleでも使ってみるかね。HTMLが欲しくなったら、薄いラッパをかませばいいし。@bibrostさんもそんな構成勧めてた気がする！

ScalaからMongoDBに接続するにはどうすればいいかなー。「Scala MongoDB」でGoogle検索。どれどれどんなドライバ使ってんのかなー&hellip;。１位、Salat。２位、lift-mongodb。３位、Casbah。ぎゃー。全部名前違うやんけ！不吉な香りがするぞ。

んでも、それぞれ中身を見てみると、SalatはCasbahを用いたO/Dマッパー、lift-mongodbはLift内にあるドライバらしい。Liftは使わないし、依存関係も軽くしたいので、Salat/Casbahを使うしかない。MongoDBを使うので、せっかくだったらO/Dマッパー使ってみるか。O/Rマッパーはあんまり使ったことないけど。O/Dマッパーって単語は正しいのかしら。

Rogueとか、Java阪ドライバのScalaラッパとかもあるらしい、という文章が目に入った気がするが、全力でスルー。

調査の結果、要件ざっくり決める。こんな感じだろ。
<ul>
	<li>Herokuでホスティングする</li>
	<li>Scalaで書く(はじめて)</li>
	<li>MongoDBをストレージとする(はじめて)、Salatでつなぐ</li>
	<li>finagle使う(はじめて)</li>
	<li>test firstで書いてみる(ニガテ)</li>
	<li>Webクライアントは、HTML5 + CSS3 + jQuery(まぁまぁ書ける)</li>
</ul>
「finagle MongoDB」でGoogle検索。
<a href="https://github.com/robi42/heroku-finagle-rogue" target="_blank"> Heroku + finagle + MongoDBのサンプルコード発見!!</a>
あ、でもコイツはRogueを使ってるな&hellip;まあいい。

「finagle Salat」でGoogle検索。
ムムム&hellip;意味ある検索結果が見つからない。

「scala MongoDB Heroku」でGoogle検索。
<a href="http://devcenter.heroku.com/articles/scaling-out-with-scala-and-akka " target="_blank"> Scaling Out with Scala and Akka on Heroku</a>ってのが見つかる。
メモっとこ。

検索結果を見ていると、またよさげなものが見つかる。
<a href="http://janxspirit.blogspot.com/2011/01/quick-webb-app-with-scala-mongodb.html" target="_blank"> A Quick WebApp with Scala, MongoDB, Scalatra and Casbah</a>
Scalatraだけど、それ以外の部分は参考になりそう。

まあ、こいつらを見ながら悪魔合成的にテストコードを書いていけば、
Scala + MongoDB + finagle + Salat on Heroku
でコード書いていけるだろう。

タイミングがよいことに、今週は以下の２つの勉強会に参加することに。
<a href="http://atnd.org/events/20683" target="_blank">MongoDB ソースコードリーディング</a>
<a href="http://partake.in/events/23b82f44-aaed-4479-a2e3-488cfdabcce2" target="_blank">Scala勉強会第56回 in 渋谷</a>
いろいろ情報仕入れられそう。

プログラムは、ニコ生のライブコーディングでガシガシ仕上げていく予定。
次回に続く。
