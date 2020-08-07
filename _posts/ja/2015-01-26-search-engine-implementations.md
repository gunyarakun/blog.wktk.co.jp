---
date: 2015-01-26 03:16:03
lang: ja
layout: post
tags: [tech]
title: 【作ってみた】書籍「検索エンジン自作入門」を読んで検索エンジン作ってみたリスト
---
私が山田浩之さんと共著させていただいた「検索エンジン自作入門」は、検索エンジンについて実際のプログラムを参照しながら解説を行った書籍です。

{% amazon jp:4774167533:detail %}

そのプログラムは、言語はC言語、データベースはSQLite、データソースはWikipediaを用いています。

読者の方が、自らの得意なプログラミング言語、データベースやデータソースを用いて実際に検索エンジンを書いてくださっているようです。うれしいので、それらを紹介させていただきます！

## PHP

- [id:masayuki5160さんこと、たなかしさんによる、PHPでつくる全文検索エンジン](http://masayuki5160.hatenablog.com/entry/2014/11/16/181634)

PHPはWebエンジニアにとって身近なプログラミング言語です。データソースもTwitterを用いていて、Webエンジニアにとって親しみやすい実装になっています。

## Python

- [id:nwpct1さんこと、めじろさんによる、Pythonでつくる検索エンジン(Webクローラ, Mecab, MongoDB, Flask)](http://nwpct1.hatenablog.com/entry/python-search-engine)

Python製のドキュメント生成ツールSphinxのドキュメントをクロールして検索可能とするものです。MongoDBを用いて、トークンごとに、そのトークンが出現するURLのリストを保存しています。

ちなみに、Pythonといえば、[Pythonだけで書かれた検索エンジンWhoosh](https://bitbucket.org/mchaput/whoosh/wiki/Home)というものもあります。

## Node.js

- [id:hideackさんによるNode.js + Redisによる実装](http://hideack.hatenablog.com/entry/2015/01/01/141801)

RedisのSet型を用いて、複数のトークンを用いた検索が高速に行えるような工夫がされています。Redisは便利な型が多くてうれしいですよね。

Redisは、Sorted Setという型でデータを保存できます。この型も、転置インデックスの保存に適したデータ型です。あるkeyに対して、文字列と数値のペアを要素とするリストを保存することができます。内部では、Skip Listというアルゴリズムを使って、リスト操作の高速化を行っています。

Sorted Setを用いた検索エンジンの例として、[Writing a simple keyword search engine using Haskell and Redis](http://www.fatvat.co.uk/2011/06/writing-simple-keyword-search-engine.html)のエントリは参考になります。

## まとめ & 実装募集中！

「検索エンジン自作入門」を読んで、ぜひぜひ検索エンジンを実際に作ってみましょう! あなたの好きな言語、DBMSで実装しましょう。

作ってみた方は、ぜひ Twitter: [@gunyarakun](https://twitter.com/gunyarakun/) か、[検索エンジン自作入門の公式ページ](http://gihyo.jp/book/2014/978-4-7741-6753-4)のお問い合わせからお知らせいただけるとありがたいです。随時追記させていただきます。
