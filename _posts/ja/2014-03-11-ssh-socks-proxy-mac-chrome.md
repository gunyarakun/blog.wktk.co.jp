---
date: 2014-03-11 06:56:01
lang: ja
layout: post
tags: [tech]
title: ssh経由のSOCKSプロキシを通じてMac上のGoogle Chromeでブラウジング
---
自分用メモ。

## SOCKSとは

汎用UNIX socketプロキシみたいなヤツ。[WikipediaのSOCKS記事を参照](http://ja.wikipedia.org/wiki/SOCKS)。つか今までぜんぜん存在知らなかった。ヤバい。

OpenSSHのクライアントは、SOCKSによるダイナミックポートフォワーディングをサポートしている。あたかもssh先のサーバからsocket通信しているかのようにできる。

特定のIPアドレスからしか閲覧できないWebサイトをWebブラウザから閲覧したい場合がある。squidみたいなHTTP proxyを立てたり、VPNのソフトウェアを入れなくても、sshを通じたSOCKSプロキシだけで、そういったWebサイトを閲覧することができる。

## OpenSSHでの接続方法

-DでSOCKSプロキシとしてListenするポート番号指定。1080が慣習のようですがなんでもよい。-fでbackground実行、-Nでremote commandを実行しない、つまりシェルを開かない。SOCKSプロキシとして使うときには両者をつけるとよいだろう。

<pre class="prettyprint">
ssh -f -N -D 1080 user@example.com
</pre>

## Macでの設定

ネットワーク環境設定で、SOCKS Proxyを使って通信が出来るようになる。

## Mac上でのGoogle ChromeでのSOCKSプロキシ利用方法

Macのネットワーク設定でSOCKSプロキシは設定できる。しかし、深遠なる理由によってそれがかなわない場合もある。

例えば、Macの非標準のVPNソフトウェアを使っていて、そのVPNソフトウェア経由でないと踏み台サーバにsshできない、といった場合だ。

いくつかのアプリケーションは、自前でSOCKS経由でのアクセスに対応している。Google Chromeもそうだ。DNSによる名前解決もSOCKS経由でやってくれる。

shell経由で、以下のように起動できる。

<pre class="prettyprint">
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --proxy-server="socks5://127.0.0.1:1080" &
</pre>

以下のようなaliasを書いておくとよいだろう。ついでにopenを使ってみた。

<pre class="prettyprint">
alias chrome="open /Applications/Google\ Chrome.app/ --args --proxy-server=\"socks5://127.0.0.1:1080\""
</pre>

SOCKSサーバがDNSによる名前解決を必要とする場合、--host-resolver-rules="MAP * 0.0.0.0 , EXCLUDE hostname" のようにして、SOCKSサーバの名前解決だけはSOCKS経由でやらないような配慮が必要となる。今回は127.0.0.1の直IPだし、localhostに変えてもhostsで名前解決できるのでいらない。