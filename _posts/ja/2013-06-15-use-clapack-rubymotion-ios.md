---
layout: post
title: RubyMotionでAccelerate Framework(vDSP, BLAS, LAPACK etc.)の関数を使う
lang: ja
tags : [ruby, rubymotion, ios]
---
RubyMotionのiOSターゲットで数値計算ライブラリを使いたい。

iOS 4.0以降には、Accelerate Frameworkというものが用意されている。

Accelerate Frameworkは数値計算ライブラリvecLibと画像計算ライブラリvImageからなる。vecLibは、数値計算ライブラリであるBLAS, LAPACK, vDSPからなる。

今回は、数値計算ライブラリLAPACK(のC言語版であるCLAPACK)にある、非対称行列の固有値を求めるdgeev_()関数を使いたい。<a href="http://blog.wktk.co.jp/ja/entry/2013/06/14/formant-detection-with-numpy">音声からのフォルマント抽出をしたいからだ。</a>

## RubyMotionでなんかXCodeだと使える関数を探す方法

さて、RubyMotionではどうするんだべ。こういうときには以下のコマンドをよく使う。

<pre class="prettyprint linenums lang-bash">
> grep -R "function_name" /Library/RubyMotion/data/ios
</pre>

どや顔で書くこともないですね。bridgesupportというインターフェースを定義するファイルが置いてあるので、そこをgrepればなんとかなるという仕組みです。

## んで欲しい関数はあったのか

dgeev_()関数を探しても見つからなかった。むむむ。しかし、/Library/RubyMotion/data/osx以下には見つかる。すなわち、OSXターゲットでは使えてiOSターゲットでは使えないのだ。なんでだろう。

というわけで、Accelerate Frameworkのbridgesupportファイルを読んでみる。

<pre class="prettyprint linenums lang-bash">
> cat /Library/RubyMotion/data/ios/6.0/BridgeSupport/Accelerate.bridgesupport
</pre>

<pre class="prettyprint linenums lang-xml">
&lt;?xml version='1.0'?&gt;
&lt;signatures version='1.0'/&gt;
</pre>

ひ〜、空じゃん。

とりあえず、motion supportで「RubyMotionでも使えるようにしてくださーい」とお願いするチケットは送るとして、俺はどうしよう。

## Objective-Cで書けばいいじゃない(マリー・アントワネット的に)

はい、Objective-Cで書いちゃいます。空なのはしょうがないですし、上記部分はオープンソース化されていない部分っぽいので、Pull Req.も送れねー。

んでも、僕Objective-C書けないのです。大丈夫でしょうか。大丈夫です。以下の手順で、CLAPACKのdgeev_()関数が使えました。もちろんvecLibの関数でも、vImageの関数でも以下の手順で使えます。

1. vendor/Oreore/Oreore.mとOreore.hを作る。
2. Oreore.hに#import <Foundation/Foundation.h>と、@interface Oreore : NSObject { メンバ変数たち }を書く
3. Oreore.mに、#import <Oreore.h>と、#import <Accelerate/Accelerate.h>と、@implementation Oreoreを書く。
4. RakefileのMotion::Project::App.setupの中で、app.vendor_project('vendor/Oreore', :static)を追加する。
5. あとは、Oreore.h/mに新しいメソッド定義を追加して、そのメソッドの中で普通にdgeev_()を呼び出す。
6. RubyMotion側からは、Oreore.alloc.initすれば当該クラスのインスタンスが得られる

という感じ。意外と簡単。Objective-Cは雰囲気で。

## まとめ

というわけで、結局RubyMotion for iOS自体は2013/06/15時点でAccelerate Frameworkに対応していないようだ。OSXでは対応しているし、チケットも送ったので、じきに対応されるものと考えている。

なお、CLAPACKの一部関数は、精度をdoubleではなくfloatにしないと、iOSシミュレータでは動くが実機は動かない、という記述をネットで見かけた。もう陳腐化している情報なのかもしれないけど、一応メモしておく。
