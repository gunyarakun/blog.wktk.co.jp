---
layout: post
title: データベースからランダムにレコードを1つだけ取り出す方法(MediaWiki編)
lang: ja
tags : [rdbms, mysql, php]
---
「ランダムで何かの要素を表示したい」という要件を見かける。難易度は低い。すぐ実装できる。が、それなりにスケールする実装は簡単ではない。

<blockquote class="twitter-tweet"><p>カウンター、ランキングなど、「コンピュータだとすぐできそうじゃん」と思えるようなことを、スケールする実装に仕上げるのは難しい。</p>&mdash; グニャラくん (@gunyarakun) <a href="https://twitter.com/gunyarakun/statuses/326538208420712449">April 23, 2013</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

MediaWikiというソフトウェアがある。Wikipediaで使われているWikiソフトウェアだ。Wikipediaにも「<a href="http://ja.wikipedia.org/wiki/%E7%89%B9%E5%88%A5:%E3%81%8A%E3%81%BE%E3%81%8B%E3%81%9B%E8%A1%A8%E7%A4%BA">おまかせ表示</a>」という機能がある。記事をランダムに1つ表示してくれる機能だ。さすがにWikipediaで使われている機能なので、スケールする実装になっているだろう。

<a href="https://git.wikimedia.org/blob/mediawiki%2Fcore.git/403b4fed47989741c0164ff97d674dd32aebfb40/maintenance%2Ftables.sql#L250">MediaWikiのレポジトリのmaintenance/tables.sql</a>にテーブル定義がある。ここで着目するのは、pageテーブルのpage_randomというカラムである。

<pre class="prettyprint linenums lang-sql">
CREATE TABLE /*_*/page (
  /* 中略 */
  -- Random value between 0 and 1, used for Special:Randompage
  page_random real unsigned NOT NULL,
  /* 中略 */
) /*$wgDBTableOptions*/;

CREATE INDEX /*i*/page_random ON /*_*/page (page_random);
</pre>

当該フィールドに格納される値は、0から1の値を取ると書いてある。また、インデックスが付与されている。

このフィールドは、新しいレコードが追加されるたびに乱数が代入される。乱数はおそらくレコード間で重複しないようにチェックしているはず。

<a href="https://git.wikimedia.org/blob/mediawiki%2Fcore.git/403b4fed47989741c0164ff97d674dd32aebfb40/includes%2Fspecials%2FSpecialRandompage.php"></a>ランダムにレコードを選び取る処理は、以下のように行われる。</a>

1. 0から1の乱数を発生させる
2. page_randomフィールドが乱数以上の数値を持つようなレコードをORDER BY page_random LIMIT 1で取得する
3. 2.でレコードが取得できればそのレコードを返す。そうでなければ、0以上の数値を持つようなレコードをORDER BY page_random LIMIT 1で取得する

とても単純な処理ですね。最悪2クエリ発生してしまいますが、インデックスはちゃんと効きそうです。

ニコニコ大百科作る際もこの設計を参考にした記憶があります。1件じゃなくてn件ランダムに取得したい場合にはあまり向かないでしょう。

このエントリは、えせはらさんの「<a href="http://bugrammer.g.hatena.ne.jp/nisemono_san/20130629/1372520895">サービスのデータベース周りなどをチェックしたらレスポンス速度が格段に上がった話</a>」のエントリや、mrknさんの以下のツイートに寄せたものです。

<blockquote class="twitter-tweet"><p>ランダム訪問で「グニャラくん」と「とはえ」の2つを行き来する2周期軌道に入ったまま抜けられない</p>&mdash; 二周目 (@mrkn) <a href="https://twitter.com/mrkn/statuses/351952724121759744">July 2, 2013</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>
