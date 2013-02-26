---
layout: !binary |-
  cG9zdA==
status: !binary |-
  cHVibGlzaA==
published: true
title: Scala + finagle + MongoDB + Herokuで2chクローンを作る（連載第3回）
author: !binary |-
  dGFzdWt1
author_login: !binary |-
  dGFzdWt1
author_email: !binary |-
  YmxvZ0B3a3RrLmNvLmpw
wordpress_id: 220
wordpress_url: !binary |-
  aHR0cDovL2Jsb2cud2t0ay5jby5qcC8/cD0yMjA=
date: 2011-11-06 02:23:53.000000000 +09:00
categories:
- 技術メモ
- Scala
- MongoDB
- 2chクローン
tags: []
comments: []
---
11/3に、@xuwei_k さんの誕生祝 &amp; Scalaハッカソン！に参加した。とりあえず、Hello Finagleを見ながら、Finagle製のWebサーバを立てることを目指す。まずは、静的なHTMLファイル返答するところまで作ろう。

むむむ&hellip;sbtの標準ディレクトリ構成がわからん。sbtのディレクトリ構成はMaven由来らしいので、<a href="http://maven.apache.org/guides/introduction/introduction-to-the-standard-directory-layout.html">Mavenのディレクトリ構成</a>を見る。

どうやら、src/main/webappというディレクトリを掘ればいいらしい。ホントにこれでいいのかな。「sbt resources 」でGoogle検索。そのものずばりな、<a href="http://stackoverflow.com/questions/3868708/what-are-resources-folders-in-sbt-projects-for">What are &ldquo;resources&rdquo; folders in SBT projects for?</a>という質問を発見。そこのリンクから、さらに<a href="http://stackoverflow.com/questions/5285898/how-to-get-a-resource-within-scalatest-w-sbt">how to get a resource within scalatest w/ sbt</a>を見る。

どうやら、リソースファイルのパスprefixはgetClass.getResource()で取得するのがJavaでは普通で、Scalaでもそうするらしい。Javaに詳しくないことがバレてしまう。staticに配信するHTMLファイルはsrc/main/resourcesかsrc/main/webappかどちらに置いたほうがいいのか、よくわからなくなってきたぜ。とりあえずwebappに置くことにする。

<a href="https://github.com/twitter/finagle/blob/master/finagle-example/src/main/scala/com/twitter/finagle/example/http/HttpServer.scala">finagleを用いたWebサーバのひな形（あきこ）</a>がある。どうやら、<a href="http://www.jboss.org/netty">Netty</a>が用意するHTTPハンドラを使っているらしい。このひな形をベースに、
<ul>
	<li>^/$, ^/css, ^/js -> staticなファイルを返す、mime-typeは拡張子からマッピングする</li>
	<li>それ以外は、それぞれのcaseクラスにマッピングしてハンドリングする</li>
</ul>
みたいなことを書いていけばいいだろう。しかも、パスからのdispatchで、matchとか使えばScalaっぽくなるっしょ!?

まずは、HTTP Methodのハンドリングだな。NettyのHTTPRequestのメソッドであるgetMethod()でパターンマッチするのが常道か。「"getMethod match"」でGoogle検索。それでひっかかった、<a href="http://code.google.com/p/punk/">PunkというWebフレームワーク</a>がサイズ小さそうなので読んでみる。

ソースを読む上で、vimのsyntax highlightが欲しい。
<pre class="syntax bash">sbaz install scala-tool-support
cp -R /usr/local/Cellar/scala/2.9.1/libexec/misc/scala-tool-support/vim/ ~/.vim</pre>
という風にしたら、syntax highlightがついた。いえー。

Punkでは、静的ファイルをどのように読み込み、クライアントに返しているのか。
<pre class="syntax bash">ack File</pre>
でgrep。src/main/scala/punk/PunkFilter.scalaにreadFile()というメソッドがあるらしい。
<pre class="syntax scala">    private def readFile(url: URL) = {
      scala.io.Source.fromURL(url).mkString
    }</pre>
うーむ。scala.io.Source.fromURL(url).mkStringってその場で文字列作るから、ファイルI/O待ってブロックするんじゃねーの？
FinagleのイベントループにFile I/Oも載せられるような何かはないのかなー。初心者のクセに欲張りかもしらんけど。

と思ったらあったー、<a href="https://github.com/twitter/finagle#Using%20Future%20Pools">Finagleのドキュメント内、Using Future Pools</a>。

FinagleはFutureという型をよく使うが、一種の遅延評価みたいなもんだろう。上記のサンプルに、importを補うとこんな感じか。
<pre class="syntax scala">import com.twitter.finagle.Service
import com.twitter.util.FuturePool
import java.util.concurrent.Executors

class ThriftFileReader extends Service[String, Array[Byte]] {
  val diskIoFuturePool = FuturePool(Executors.newFixedThreadPool(4))

  def apply(path: String) = {
    val blockingOperation = {
      scala.Source.fromFile(path) // potential to block
    }
    // give this blockingOperation to the future pool to execute
    diskIoFuturePool(blockingOperation)
    // returns immediately while the future pool executes the operation on a different thread
  }
}</pre>
このThriftFileReaderを実行してみると、型エラーが出た。fromFileはscala.io.BufferedSourceを返すが、FuturePool.apply()は、Array[Byte]を受け取る。scala.io.BufferedSourceからArray[Byte]に変換する方法を調べよう&hellip;と思ったけど、面倒なのでやめる。toArrayあたりでいいのかな？

とりあえず、同期でもいいからファイルをHTTP経由で返すところまでもっていこう。
<pre class="syntax scala">response.setContent(copiedBuffer(scala.io.Source.fromFile("src/main/webapp/index.html").mkString, UTF_8))</pre>
うむ。ブラウザからアクセスしたところ、index.htmlが表示された。しかし、このcopiedBufferをはさむところがなんかダサいな。

responseはNettyのHttpResponseのインスタンス。setContentはバッファを受け取る。fromFile()はscala.io.BufferedSourceを返す。setContentが受け取るのはorg.jboss.netty.buffer.ChannelBufferインターフェース互換のもの。うまくやれば直接変換できそうな予感。そうすれば、FuturePoolでラップしなくても、実際にI/Oが必要となったときにFile -> Networkに直に転送してくれたりできそうな気配がする。けど、これもあまり深追いしないでおく。

pathによってきちんと返すファイルを変えよう。
<pre class="syntax scala">response.setContent(copiedBuffer(scala.io.Source.fromFile("src/main/webapp" + request.getUri).mkString, UTF_8))</pre>
動作した。

上記のサンプルは、「/」へのアクセスでindex.htmlを返してくれない。また、ありがちな「../../../etc/passwd」的なものに弱い。前者について、HttpRequestのパスが「/」の場合には「/index.html」と解釈するようにしよう。後者について、パスを作ったあとパスの正規化をして、そのprefixをチェックする、っていうのが一般的な処理だろう。今回は、Scalaの正規表現を勉強したいので、とりあえず「..」という部分文字列があったら例外を投げるようにしてみる。

こんな感じでよかんべ。「..」にマッチする正規表現をソースコードに埋め込むのは面倒だ。最初は、"\\.\\."と書いたが、"""\.\."""とも書けるようだ。
<pre class="syntax scala">  val tentenRegex = """\.\.""".r
  val path = request.getUri

  val filePath = "src/main/webapp/" + path match {
    case tentenRegex() => throw new Exception
    case "/" => "/index.html"
    case _ => path
  }</pre>
初match！どきどき&hellip;あれれ、動作しない。ルートにアクセスしても、/index.htmlの内容を返してくれない。なんでだろ？調べてみると、pathが「/」の際に、２個目のcaseにマッチしていないようだ。なんでだ。俺たちはまだ、青春知らずさ。

ためしにifでマッチするかどうか試してみるか。
<pre class="syntax scala">  val path = request.getUri

  if (path == "/") {
    println("match de-su")
  }</pre>
match de-suって表示された。ifだとうまくいくようだ。なんでだろう。matchへの理解不足だな。とりあえず、スタンドアロンのmatch検証プログラムを書いて動作させるか。道のりは遠い。

今回の分はコミットしていないですが、<a href="https://github.com/gunyarakun/clone2ch">githubでソースコードを公開し始めました</a>。<a href="http://com.nicovideo.jp/community/co1170019">ニコニコ生放送でライブコーディング（という名のつぶやき放送）もやっております</a>。
