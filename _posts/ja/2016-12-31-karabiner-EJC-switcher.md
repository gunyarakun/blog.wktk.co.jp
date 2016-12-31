---
date: 2016-12-31
lang: ja
layout: post
tags: [language,english,chinese,karabiner,MacOSX]
title: Macで英語と日本語と中国語の入力を1発で切り替えるショートカット、ピンイン声調入力もあるよ
---
Macの英語キーボードで2言語までだったら切替するのは楽です。しかし、3言語以上になると、とたんに面倒になりませんか？僕はなりました。

中国語を勉強しているのですが、そのメモを書くのがめんどい。中国語、日本語でのメモ、声調付きのピンインの3つを入力していると狂う。

というわけで、[Karabiner](https://pqrs.org/osx/karabiner/)(旧名KeyRemap4MacBook)を使って、Ctrl-1,2,3,4でそれぞれ英語、中国語、日本語、あと1つの言語入力を選択できるショートカットキーを作成しました。そして、Ctrl-5,6,7,8で第1,2,3,4声の声調記号も入力できます。いぇい。

[GitHub:karabiner-EJC-switcher](https://github.com/gunyarakun/karabiner-EJC-switcher)

## つかいかた

１．[Karabiner](https://pqrs.org/osx/karabiner/)インストールしてください。macOS Sierraだと2016年12月現在はKarabinerが動作しないようです。

２．キーボードの入力ソースの設定で、英語、日本語、中国語など、4つ以下の入力ソースになるように調整してください。英語の入力ソースはEnglishではなく、U.S. Extendedにしといてください。声調入力で必要となります。

![入力ソースの設定例](/assets/images/entry/2016-12-31/input-source-settings.jpg)

３．Karabinerを起動して、PreferencesのMisc & UninstallのところにCustom Stteing: Open private.xmlというボタンがあるので、そこ押して出たフォルダに[private.xml](https://raw.githubusercontent.com/gunyarakun/karabiner-EJC-switcher/master/private.xml)を上書きするか、別のファイル名で置いて既存のprivate.xmlの&lt;root&gt;タグ配下にて、以下のようにincludeしてください(例はejc.xmlとして置いた場合)。

```xml
<root>
  ...(既存のなにか)...
  <item>
    <name>Karabiner EJC Switcher</name>
    <appendix>Including KarabinerEJCSwitcher.</appendix>
    <include path="ejc.xml" />
  </item>
</root>
```

４．KarabinerのPreferencesのChange Keyの右上にある、Reload XMLを押してください。

５．KarabinerEJCSwitcherの項目が出るので、有効にしたいものを選んでチェックしてください。

- Ctrl + 1, 2, 3, 4で、入力ソースの1, 2, 3, 4番目を選ぶ(1は英語、それ以外は環境依存っぽ)
- Ctrl + 5, 6, 7, 8で、四声用の声調記号入力。mā, má, mǎ, mà。üは声調なしのときはU.S. Extendedを選びOption+uのあとuで、声調付きの場合は、声調記号入力後にvを押してください。

![KarabinerのChange Key設定画面](/assets/images/entry/2016-12-31/karabiner-preferences.jpg)

６．Enjoy!

## Mac入力言語一発切り替えショートカット POCHI

韓国在住のMinoruさんによる、[POCHI](http://seoul-life.blog.jp/archives/41528657.html)というKarabiner用多言語切替ショートカットキー作成ファイルがあります。

いろんな言語のいろんな機能に対応していて超便利なんですが、自分でカスタマイズしようとしたときにどこを修正すればいいのか迷ってしまいます。僕のprivate.xmlはPOCHIを参考にしつつ、自分が欲しい機能のみにしぼったものです。Minoruさん、ラブ&感謝。

Karabinerのインストールとかprivate.xmlの置き方はPOCHIのサイトのほうが詳しいと思うので、困ったらGO!

## カスタマイズ

まあ見ればだいたい分かるやろ。デバッグ用に、EでKarabinerのイベントビューワ、RでKarabinerのReload XMLを行うようにする機能もPOCHI由来で入っているので、それも使って頑張ってちょ。

なんかあれば[GitHubのissuesかpull request](https://github.com/gunyarakun/karabiner-EJC-switcher)で。よろぴく。

## 暮れの元気なご挨拶

2016年はお世話になりました。来年2017年も本ブログよろしくお願いいたします。
