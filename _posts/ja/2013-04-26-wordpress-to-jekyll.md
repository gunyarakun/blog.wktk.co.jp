---
layout: post
title: はてなとWordpressから最強ブログシステムに移行する
lang: ja
tags : [intro, beginner, jekyll, tutorial]
---
もともと僕は静的ファイル信者なのですが、blogはWordPressで運用していたのでした。WordPressは、すでにひとつの実行環境であり(like Emacs)、機能もプラグインも豊富だけど、ちょこっと自分好みにいじろうとすると、とたんに面倒になるものでした。

具体的には、以下のようなことに悩まされていたわけです。

- 重い
- Apacheを前提としているプラグインがある
- プラグインの食い合わせを調整するのが面倒
- デザインをちょっと修正するのが面倒

というわけで、Jekyllを使った静的ファイル作成に切り替えてみたのでした。ああなつかしきMovableType的静的ファイルpublishの世界。

## Jekyll環境の準備

[てっく煮ブログ](http://tech.nitoyon.com/ja/blog/)にある、[俺の最強ブログ システムが火を噴くぜ](http://tech.nitoyon.com/ja/blog/2012/09/20/moved-completed/)を参考にちゃちゃっと準備しました。

Jekyll bootstrapというものを最初採用しようかと思ったのですが、Jekyll bootstrapの文法にしたがっていろいろ設定しなければならず、Wordpressで悩んだ悩みと近い悩みをかかえることになるのでパス。てっく煮ブログのid: nitoyonさんのシステムをベースにしました。

## rakutenプラグインの実装

僕のブログでは楽天市場の商品をたまに紹介していたのですが、Jekyllの楽天プラグインは存在していなさそうです。というわけで、id:nitoyon様のAmazonプラグインを参考にして、適当にこしらえてみました。

https://github.com/gunyarakun/blog.wktk.co.jp/blob/master/_plugins/tags/rakuten.rb

一応、rakutenというgemがあるのでそれを使おうかと思ったのですが、楽天の商品検索API version 2に対応してないっぽかったので、適当に仕様読んで実装しました。open-uriを使っているのはrakuten gem由来。

## Wordpressからの移行

JekyllのWikiにある[Blog Migrations]を参考に、migratorを実行しました。ただし、なんかいろいろ細かい問題が発生したので、スクリプトによる修正や手修正を行いました。

- 余計なヘッダ出過ぎ。
- タグの前後に改行をはさんでくれないので、Markdownの<p>タグが変なところに入ってしまう。
- Google Code Prettifyを使うように。
- Wordpressのtagを、Jekyllのcategoriesに変更。

Wordpressから移行したエントリは、Wordpressと同じURLになるように調整しました。permalinkという属性で、エントリごとのパスを指定することができます。

Jekyllで出力されるのは、基本'パス名/index.html'というファイルです。よって、iURLのお尻に「/」がついてしまいます。これを避けるために、Nginxでrewriteするようにしました。

<pre class="prettyprint">
      rewrite ^(/archives/\d+)$ $1/ last;
      rewrite ^(/ja/entry/.+[^/])$ $1/ last;
</pre>

## はてなからの移行

id:nitoyon センパイのblogでは、はてなと自ドメインで同じようなコンテンツを配信しているのにもかかわらず、はてな側のページを閲覧するとリダイレクトして独自ドメインのページに移動します。HTTPヘッダにも、metaタグにもリダイレクトが入っていないのに、どうやってるんじゃろう。

[ブログパーツを使っていたのでした。](http://tech.nitoyon.com/ja/blog/2007/08/20/javascript-eval-on-hatena-diary/)つか、このエントリもid:nitoyon製。

id:nitoyonアニキのconvert\_hatena\_to\_jekyll\_posts.rbでだいたいはうまくコンバートすることができました。

- MML記法、AA記法には対応していませんでした。(マイナーすぎる)
- シンタックスハイライトライブラリであるPygmentsがClearSilverというテンプレートエンジンのHDFファイルに対応していませんでした。(さらにドマイナー)
- もともとタイトルが付与されていないエントリの変換がうまくいきませんでした。

というわけで、ちょこちょこ修正してコンバートしたものの、全エントリを目視チェックするのが面倒なので、まだはてなからの移行は完了していません。

## デザイン

無理っす。オデ、デザイン、ムリッス。無理なので、シンプルなものにしました。

要件はこんな感じ。

- テキスト読みやすい
- 落ち着いた感じ
- スマフォで読みやすい
- なんか1個くらいcss animationでもつけたい

まず、Vertical Rhythmを採用しました。下記の参考サイト曰く、「ページ全編の行間サイズを揃えて、「リズム感」を整えようではないか！そうすれば文章が読みやすくなり、デザイン性も向上し、何よりもサイトを見る側のストレスが減るので、実にGoodだ！」ということらしいです。

- [脳に優しいデザインを！「Vertical Rhythm」の基本と実現方法](http://liginc.co.jp/designer/archives/12071)

落ち着いた感じは、ズルいデザインテクニックより、ズルいbox-shadowを採用してみました。

- [少ない手間と知識でそれなりに見せる、ズルいデザインテクニック with Sass / Compass](https://speakerdeck.com/ken_c_lo/zurui-design)

スマフォで読みやすい感じは、[Rubyのbetter_errors](http://morizyun.github.io/blog/better-error-gem-rails-ruby-rack/)に影響されて、基本２カラム、幅が狭い場合にはMedia Queriesで１カラムにまとめるようにして対応してみました。

ワンポイントのCSS animationは、Erik Deinerによる[Twitter Button Concept](http://dribbble.com/shots/457259-Twitter-Button-Concept)を実装した、[CodePenにあるsnippet](http://codepen.io/bennettfeely/pen/ErFGv)を取り入れました。

CodePenは[-prefix-free](http://leaverou.github.io/prefixfree/)が自動的に有効となるので、[CompassのCSS3 module](http://compass-style.org/reference/compass/css3/)を使って移植しました。

## まとめ

最強ブログシステムは、ひととおりできてしまえば、運用がとてもラクなシステムでした。WordpressからURLを変えずに移行できた、というのはうれしい誤算です。

ぜひぜひ最強ブログシステムを活用してみてください。
