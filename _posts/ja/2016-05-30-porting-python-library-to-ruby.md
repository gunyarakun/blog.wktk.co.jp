---
date: 2016-05-30 17:49:23
lang: ja
layout: post
tags: [tech,ruby,python]
title: 位置情報によるタイムゾーン取得Gem timezone_finderで学ぶPythonからRubyへの移植法
---
timezone\_finderというGemを登録しました。

- https://rubygems.org/gems/timezone_finder
- https://github.com/gunyarakun/timezone_finder

緯度・経度を与えると、その緯度・経度でのタイムゾーン文字列を取得することができるライブラリです。海上であっても、最寄りのタイムゾーン文字列を取得することができます。

GeoIPと組み合わせることによって、IPアドレスからタイムゾーンを推定できます。こんな感じ。

<pre class="prettyprint lang-ruby">
require 'maxminddb'
require 'timezone_finder'

db = MaxMindDB.new('./GeoLite2-City.mmdb')
ret = db.lookup(request.remote_ip)
tf = TimezoneFinder.bew
puts tf.timezone_at(ret.location.longitude, ret.location.latitude)
</pre>

さて、このGemはもともとPythonのライブラリであった[timezonefinder](https://github.com/MrMinimal64/timezonefinder)をRubyに移植したものです。

経験上、Pythonのライブラリは、比較的Rubyに移植しやすいです。今回は、移植にときに気をつけた内容をメモしておきます。

みなさんも、PythonにあってRubyにないライブラリがあれば、じゃんじゃん移植しちゃいましょう。

## PythonからRubyに移植するときやったこと

### Python 3以降の割り算

Python 3以降では、整数同士の割り算が浮動小数点数になる。Python 2で\_\_future\_\_.divisionをimportしてもそうなる。Rubyでは、定数があればその定数を小数化しておくか、Numeric#fdivを使う。

<pre class="prettyprint lang-python">
from __future__ import division, print_function

print(a / 2)
print(a / b)
</pre>

<pre class="prettyprint lang-ruby">
puts (a / 2.0)
puts a.fdiv(b)
</pre>

### dictでキーが見つからないときの挙動

例外出るパターンとデフォルト値設定パターンのマッピングに気をつける。

<pre class="prettyprint lang-python">
{'a': 'entry a'}['b']                # raise
{'a': 'entry a'}.get('b')            # None
{'a': 'entry a'}.get('b', 'default') # 'default'
</pre>

<pre class="prettyprint lang-ruby">
{'a' => 'entry a'}.fetch('b')            # raise
{'a' => 'entry a'}['b']                  # nil
{'a' => 'entry a'}.fetch('b', 'default') # 'default'
</pre>

### numpy

Pythonのライブラリ、気軽にnumpy使っていたりする。numpy.arrayは(多次元)配列で。numpy.fromfileは自前で実装した。

<pre class="prettyprint lang-python">
from numpy import empty

empty_array = empty([2, nr_points], dtype='f8')
</pre>

<pre class="prettyprint lang-ruby">
empty_array = [[0.0] * nr_points] * 2
</pre>

### 変数のスコープ

Pythonのdefはクロージャがあり、Rubyのdefはそうでない。グローバル変数化したり、クラス・インスタンス変数化したり、引数に入れたり、好きに処理しよう。

<pre class="prettyprint lang-python">
a = []
def funca():
  b = []
  a.append(1)
  def funcb(n):
    b.append(n)
  funcb(2)
  return a + b

print(funca())
</pre>

<pre class="prettyprint lang-ruby">
class Klass
  def initialize
    @a = []
  end

  def funca()
    b = []
    @a << 1
    def funcb(n, b)
      b << n
    end
    funcb(2, b)
    return @a + b
  end
end

puts Klass.new.funca().to_s
</pre>

### pack/unpack

Pythonの場合はstruct配下にあるが、RubyはArray#packとString#unpack。フォーマットの文字列が違うので注意。

<pre class="prettyprint lang-python">
from struct import pack
# big endian 16bit
pack(b'!H', val).unpack(b'!H')[0]
</pre>

<pre class="prettyprint lang-ruby">
# big endian 16bit
[val].pack('S>', val).unpack('S>')[0]
</pre>

### 予約語

Pythonでの予約語とRubyでの予約語の違いに気をつける。変数名endとか。

<pre class="prettyprint lang-python">
for ID in ids:
  start = starts[ID]
  end = ends[ID]
  print(start, end)
</pre>

<pre class="prettyprint lang-ruby">
ids.each do |id|
  start = starts[id]
  last = latss[id]
  puts [start, last].to_s
end
</pre>

### トリプルクォーテーション

ヒア文字列に変える。ドキュメンテーション文字列の場合は、余裕があればRDoc用のコメントにする。

### for文/range

Rubyでもfor式は使えるが、基本Enumerable#eachを使うように書き換える。for残してもいい。

<pre class="prettyprint lang-python">
for i in range(n):
</pre>

<pre class="prettyprint lang-ruby">
(0...n).each do |i|
end
</pre>

<pre class="prettyprint lang-python">
for i in range(1, n, 2):
</pre>

<pre class="prettyprint lang-ruby">
(1...n).step(2) do |i|
end
</pre>

Enumerable#step使ったり。

<pre class="prettyprint lang-python">
for i in range(1, n, 2):
</pre>

<pre class="prettyprint lang-ruby">
(1...n).step(2) do |i|
end
</pre>

uptoや..も好みに応じて。

<pre class="prettyprint lang-python">
for i in range(n + 1):
</pre>

<pre class="prettyprint lang-ruby">
(0..n).each do |i|
end
# or
0.upto(n).each do |i|
end
</pre>

### リスト内包表現

だいたいArray#mapで。

<pre class="prettyprint lang-python">
[func(x) for x in list1]
</pre>

<pre class="prettyprint lang-ruby">
list1.map { |x| func(x) }
</pre>

list幅の配列初期化に使われている場合はArray#\*で。

<pre class="prettyprint lang-python">
[False for x in list1]
</pre>

<pre class="prettyprint lang-ruby">
[false] * list1.length
</pre>

### listへのappend

Array#pushへの置き換えでよいが、個人的にはArray#<<を使うのが好き。

<pre class="prettyprint lang-python">
l = []
l.append(1)
</pre>

<pre class="prettyprint lang-ruby">
l = []
l.push(1)
# or
l << 1
</pre>


### print

\_\_future\_\_.print\_functionをimportして関数形式のprintを使っているかどうかにもよるが、putsへ寄せる。複数の値を指定している場合は気をつける。

<pre class="prettyprint lang-python">
print(a)
print(a, b)
</pre>

<pre class="prettyprint lang-ruby">
puts a
puts a, b           # puts aとputs bを連続して実行したのと同じ
puts [a, b].to_s    # こうするとPythonの出力に少し似る
puts "(#{a}, #{b})" # a, bが数値ならこれでPythonの出力と合う
</pre>

### デストラクタ

Objectspace.define\_finalizerで。

<pre class="prettyprint lang-python">
  def __init__(self):
    pass

  def __del__(self):
    print('ie-i')
</pre>

<pre class="prettyprint lang-ruby">
  def initialize
    ObjectSpace.define_finalizer(self, self.class.__del__)
  end

  def self.__del__
    proc do
      puts 'ie-i'
    end
  end
</pre>

### あとこまかいの

ここらへんは変換を続けていくと、脊髄反射でコンバートできる。

- `None` => `nil`
- `True` => `true`
- `False` => `false`
- `elif` => `elsif`
- `max(a, b)` => `[a, b].max`
- `min(a, b)` => `[a, b].min`
- `len(a)` => `a.length`
- `floor()`/`ceil()`/`round()` => `x.floor`/`x.ceil`/`x.round`
- `int()`/`float()` => `to_i`, `to_f`
- `tuple` => `Array`
  - 単なるカッコなのでミスしやすい、注意。Hashのキーにもできる。
- `set` => `Set`
- `ValueError` => `ArgumentError`
- キーワード引数は、場合によってそうしたりそうしなかったり
- 最後の式のreturnを抜いたりとかは趣味で

## 感想

- PythonからRubyへのライブラリ移植は、ほぼ単純作業でいける
- numpyとか気軽に使ってくるのでガマンする
- 小数、タプルまわりはバグりやすいので気をつける

では、timezone\_finderぜひぜひごひいきに。
