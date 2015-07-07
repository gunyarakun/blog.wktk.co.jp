---
date: 2015-07-07 02:33:06
lang: ja
layout: post
tags: [english,chrome]
title: Netflixの英語字幕に日本語訳をつけるChrome拡張「Netflix Subtitles Extender for Japanese」をリリースしました
---
アメリカはサンフランシスコに1年半ほど住んでおりますが、基本引きこもりです。ブルーボトルコーヒーとか行ったことないし。なので英語が全く上達しません。ヤバいです。

[Netflix](http://www.netflix.com/)というサービスで映画でも見まくって英語でも学習すっか、と思って映画を見ていたのですが、英語字幕に分からない単語が出てくる。いちいち停止して、辞典を引けばよいのですが、それも面倒です。

というわけで、Netflixの英語字幕に以下のような加工を加えるChrome拡張、[Netflix Subtitles Extender for Japanese](https://chrome.google.com/webstore/detail/netflix-subtitles-extende/gmdblbkipolimdnmbmofockgeeamalhj)をリリースしました。

- 単語ごとに日本語訳のルビをつける
- 単語をクリックするとWeb辞書で単語の意味を調べられる

これで映画での英語学習がはかどりますね！

スクショはこんな感じ。legendもlyingも訳語多すぎやろ、と思いますよね。その事情はあとで述べます。

![ローマの休日でのスクリーンショット](/assets/images/entry/2015-07-07/capture_roman_holiday.jpg)

### 字幕ルビ付与用の辞典開発

字幕において、日常的に頻出する語にまでルビをつけると、かなりうざったくなってしまいます。そこで、辞典の見出し語ごとに頻度情報を持ち、それに応じてルビをつけるかつけないかを決めることができるようになればよいと考えました。

[American National Corpus Frequency Data](http://www.anc.org/data/anc-second-release/frequency-data/)で公開されている、出現頻度別の語リストというものがあります。これは、当該コーパスの中での語の出現頻度のデータです。便利！

しかも！ その出現頻度に基づいて、[Jam Systems Inc.](http://www.jamsystem.com/index.html)によって、[ANC(American National Corpus)準拠 英和頻度辞典(28,000語)](http://www.jamsystem.com/ancdicfreq.html)という辞典まで作られています。便利。これ、そのまま使えばよいのでは？

しかし、この辞典の訳語は、字幕の上に訳語として表示するためには適さないものがあります。例えば、百科事典的な解説です。

というわけで、ANC準拠 英和頻度辞典を元にして、[簡短英日辞典](https://github.com/gunyarakun/kantan-ej-dictionary)という辞典を作成しました。元の時点に比べて、訳語の数を減らしたり、口語的にしたりと、字幕に日本語訳のルビを振るという用途に合うように変更を加えました。とはいえ、まだまだ変更が必要な品質であるのが現状です。上掲のスクリーンショットを見ても推測できますし、実際にChrome拡張を使ってもらうと、より実感するでしょう。

### 品詞の推定

例えば、動詞であれば三単現、時制、分詞など、語尾に変化がある語を辞典で調べる場合には、原型に戻す必要があります。その活用が不規則だったりとかすると、もう狂いそうになりますね。

そこで、[nlp_compromise](https://github.com/spencermountain/nlp_compromise)というモジュールを使いました。このモジュールは、文章から単語ごとの品詞推定ができ、さらに原型は何か、などを教えてくれます。素晴らしいですね。

ただし、字幕の場合、1文が字幕の範囲を超えたりすることがあります。よって、当モジュールでは割り切って、文章ではなく単語ごとに品詞推定させています。その副作用で精度が落ちているのですが、泥縄な対応でなんとか押さえ込んでいます。

## むすび

アイデアは単純ですが、実現は結構めんどくさかった。

辞典の品質、拡張そのものの品質ともに、まだまだ改善の余地があります。辞典である[簡短英日辞典](https://github.com/gunyarakun/kantan-ej-dictionary)はオープンソースなので、修正があればpull requestいただけるとうれしいです。

日本のIPアドレスからはNetflixを見ることができないので、ニッチな拡張です。今秋Netflixが日本でサービスを始めるらしいので、その際にはぜひぜひ活用してあげてください。
