---
date: 2016-07-01 18:04:25
lang: ja
layout: post
tags: [tech,ruby]
title: RubyでJavaなどのinterfaceっぽいことをしたい
---
ダックタイピングだから〜、とかそういうのは承知の上で、Rubyで特定のメソッドを実装していることを明示的に表したい。

具体的には、Objective-C実装に構造を似せたRubyのプログラムを書きたい。Objective-Cで〜Delegateなどのprotocolよく使うでしょ。それ用。

ググると、テストで担保しろ、という意見があった。メタプログラミング的にmethod\_missing使って特定のメソッド群があることを確認、とかもいける？

僕はとりあえず、`NotImplementedError`を投げまくるmoduleを作り、それをincludeして再定義してあげるようにした。

- 特定のインターフェースを実装しているんだよという宣言がある
- 実際にメソッドを呼ぶときに、未実装のものが呼び出されれば実行時にraiseされる

というわけで、やりたいことは満たせた感じ。

<pre class="prettyprint lang-ruby">
#!/usr/bin/env ruby

module SomeInterface
  def method1
    raise NotImplementedError
  end
end

class SomeClass
  include SomeInterface

  def method1
    puts 'method 1 dayo-'
  end
end

SomeClass.new.method1
</pre>

もっといい方法があれば教えてください。
