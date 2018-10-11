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

特定のIPアドレスからしか閲覧できないWebサイトをWebブラウザから閲覧したい場合がある。squidみたいなHTTP proxyを立てたり、VPNのソフトウェアを入れなくても、sshを通じたSOCKSだけで、そういったWebサイトを閲覧することができる。

## OpenSSHでの接続方法

-DでSOCKSとしてListenするポート番号を指定できる。1080が慣習のようですがなんでもよい。-fでbackground実行、-Nでremote commandを実行しない、つまりシェルを開かない。SOCKSプロキシとして使うときには-f -Nともにつけるとよいだろう。

<pre class="prettyprint">
ssh -f -N -D 1080 user@fumidai.example.com
</pre>

.ssh/configにも各種設定を書ける。

<pre class="prettyprint">
Host fumidai.example.com
  User user
  Protocol 2
  ForwardAgent yes
  DynamicForward 1080
</pre>

## Macでの設定

ネットワーク環境設定で設定すれば、SOCKSを使って通信が出来るようになる。

注意するのは、Bypass proxy settings for these Hosts & Domainsという例外設定に、ssh先のサーバを入れておくことと、Exclude simple hostnamesのチェックをつけておくこと。前者はないとうまく動かないし、後者はlocalhostなどへの通信まで奪われてしまう。

![Macのネットワーク環境設定におけるSOCKS Proxyの設定](/assets/images/entry/2014-03-11/mac_socks_proxy.png)

これで、Macのネットワーク環境設定を使うようなアプリケーションであれば、全てSOCKS proxyを通じた通信ができる。例えば、Google ChromeでのブラウジングなどはSOCKS proxy経由となる。

ただし、コマンドラインアプリケーション、例えばsshなどは、このSOCKS Proxyを使って通信しない。

ありとあらゆる通信をSOCKS proxy経由にする場合は、[Proxifier](http://www.proxifier.com/mac/)などを導入する必要がある。

sshだけであれば、ssh -Wを使うとよい(netcatを使う方法もあるが、割愛)。target.example.comがアクセスしたい先のホスト名。ポート番号などが違う場合には、ProxyCommandに適切なオプションを追加すること。

<pre class="prettyprint">
Host target.example.com
  User user
  Protocol 2
  ForwardAgent yes
  ProxyCommand ssh -W %h:%p fumidai.example.com
</pre>

## Mac上でのGoogle ChromeでのSOCKSプロキシ利用方法

上記で述べたとおり、Macのネットワーク設定でSOCKSプロキシは設定できる。しかし、深遠なる理由によってそれがかなわない場合もある。

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

## Mac上でのGoogle Chromeで特定のドメインのみSOCKS経由にする

Google Chrome拡張である[Proxy SwitchyOmega](https://chrome.google.com/webstore/detail/proxy-switchyomega/padekgcemlokbadohgkifijomclgjgif?hl=ja)を入れると、特定のドメインだけをSOCKS経由でアクセスできるようになる。

profileというものを複数作ることができて、profileごとにproxyのルールを切り替えることができる。

WebブラウジングでSOCKSを使う人にとっては便利な拡張。
