---
layout: post
title: クッキーを焼きまくるゲームCookie Clikerの攻略メモ
lang: ja
tags : [life, game]
---
[クッキーを焼きまくるゲームCookie Clicker](http://orteil.dashnet.org/cookieclicker/)が大人気のようです。僕も腱鞘炎になりそうです。

というわけで、俺用攻略メモ。随時更新するかも。

## ゲームの概要

- 画面左のクッキーをクリックするたびにクッキーが生産される。最初は1クリック1枚。
- クリックしなくても自動的にクッキーを作ってくれる、クッキー生産設備をクッキーで買える。
- 1クリックあたりのクッキー製造枚数や、クッキー生産設備の1秒間あたりのクッキー製造枚数(CpS)は、クッキーで買えるアイテムで向上することができる。なお、この両者は別物。

## ゴールデンクッキー

画面上にたまに出てくるクッキー。クリックするとよいことが起こる。

### ゴールデンクッキーの効果一覧

- frenzy: Cookieの生産が7倍になる。間隔は77秒。
- multiply cookies: 今持っているクッキー数の10%もしくは、20分間のクッキー生産数のうち低い値のクッキーをもらえる。
- click frenzy: クリック時のCookieの生産量が777倍になる。間隔は13秒。たまーに出る。
- chain cookie: 連続でクッキーが出て、それをクリックするたびに6個、66個、666個…とクッキーがもらえる。ほとんどお目にかかれない。
- clot: 未見
- ruin cookies: 未見

ゴールデンクッキーは、直前に取ったゴールデンクッキーの種類となるべく異なるように調整されている。

## 裏技

ウルテクです。以下の「javascript:」から始まる文字をブラウザのアドレス欄に入力してみましょう。

### 毎秒10クリック

<pre class="prettyprint lang-ini">
javascript:setInterval(function(){ Game.ClickCookie(); }, 100);
</pre>

by [@sh2](http://dbstudy.info/temp/cookie.txt)

### ゴールデンクッキーを5秒に1回出す

<pre class="prettyprint lang-ini">
javascript:setInterval(function(){ Game.goldenCookie.spawn(); Game.goldenCookie.click(); }, 5000);
</pre>

by [@sh2](http://dbstudy.info/temp/cookie.txt)

### 設備を10秒に1回、高い方から購入

<pre class="prettyprint lang-ini">
setInterval(function(){ for (var i = 9; i >= 0; i--) { $("#product" + i).click(); } }, 10000);
</pre>

by [@sh2](http://dbstudy.info/temp/cookie.txt)

### ゴールデンクッキー即出し

<pre class="prettyprint lang-ini">
javascript:(function(){Game.goldenCookie.spawn();})()
</pre>

by [@tokoroten](https://twitter.com/tokoroten/statuses/379283461493637120)

## 1クリックあたりのクッキー製造枚数を増やすアイテム

足し算で増えるアイテム

- Thousand fingers: 0.1枚増える。設備Cursorを20個買うとアンロック。
- Million fingers: 0.5枚増える。設備Cursorを40個買うとアンロック。
- Billion fingers: 2枚増える。設備Cursorを80個買うとアンロック。
- Trillion fingers: 10枚増える。設備Cursorを120個買うとアンロック。
- Quadrillion fingers: 20枚増える。設備Cursorを160個買うとアンロック。
- Quintillion fingers: 100枚増える。設備Cursorを200個買うとアンロック。

かけ算で増えるアイテム。足し算アイテムの効果も活きるし、かけ算同士は重ねがけできる。

- Plastic mouse: 0.01倍増える。クリックして作ったクッキー数が1,000枚でアンロック。
- Iron mouse: 0.01倍増える。クリックして作ったクッキー数が100,000枚でアンロック。
- Titanium mouse: 0.01倍増える。クリックして作ったクッキー数が10,000,000枚でアンロック。
- Adamantium mouse: 0.01倍増える。クリックして作ったクッキー数が1,000,000,000枚でアンロック。

## クッキー製造設備

### Cursor

10秒ごとに自動でクリックしてくれるヤツ。

- 初期購入クッキー量: 15
- 初期CpS: 0.1
- 設備増強アイテムアンロック設備数: 1, 10

なお、こいつで作ったクッキーは手動でクリックして作った扱いにならないので注意。

### Granma

ばあちゃん。

- 初期購入クッキー量: 100
- 初期CpS: 0.5
- 設備増強アイテムアンロック設備数: 1, 10, 50

### Farm

農園。

- 初期購入クッキー量: 500
- 初期CpS: 2
- 設備増強アイテムアンロック設備数: 1, 10, 50
- ばあちゃん増強アイテムアンロック設備数: 15

### Factory

工場。

- 初期購入クッキー量: 3,000
- 初期CpS: 10
- 設備増強アイテムアンロック設備数: 1, 10, 50
- ばあちゃん増強アイテムアンロック設備数: 15

### Mine

鉱山。

- 初期購入クッキー量: 10,000
- 初期CpS: 40
- 設備増強アイテムアンロック設備数: 1, 10, 50
- ばあちゃん増強アイテムアンロック設備数: 15

### Shipment

宇宙船。宇宙からクッキー取ってくるらしい。

- 初期購入クッキー量: 40,000
- 初期CpS: 100
- 設備増強アイテムアンロック設備数: 1, 10, 50
- ばあちゃん増強アイテムアンロック設備数: 15

### Alchemy lab

錬金術研究所。

- 初期購入クッキー量: 200,000
- 初期CpS: 400
- 設備増強アイテムアンロック設備数: 1, 10, 50
- ばあちゃん増強アイテムアンロック設備数: 15

### Portal

ワープゲートのことらしい(by [@fladdict](https://twitter.com/fladdict))。

- 初期購入クッキー量: 1,666,666
- 初期CpS: 6,666
- 設備増強アイテムアンロック設備数: 1, 10, 50
- ばあちゃん増強アイテムアンロック設備数: 15

### Time machine

昔に作ったクッキーを持ってくるそうな。

- 初期購入クッキー量: 123,456,789
- 初期CpS: 98,765
- 設備増強アイテムアンロック設備数: 1, 10, 50
- ばあちゃん増強アイテムアンロック設備数: 15

パラメータ作成がいい加減！（褒めてる）

### Antimatter condenser

反物質凝縮装置。

- 初期購入クッキー量: 3,999,999,999
- 初期CpS: 999,999
- 設備増強アイテムアンロック設備数: 1, 10, 50
- ばあちゃん増強アイテムアンロック設備数: 15
