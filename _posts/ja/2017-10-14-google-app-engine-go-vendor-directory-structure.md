---
date: 2017-10-10 21:01:23 -800
lang: ja
layout: post
tags: [tech,golang,appengine]
title: Google App EngineのGo 1.8 Standard envでdepのvendoringなどでハマる(2017年10月現在)
---
Google App EngineのGo 1.8 Standard environmentを使って、React SPAのWebサイトを作ろうと考えた。

Reactのサーバサイドレンダリングとか、欲しいものが入ってる[go-starter-kit](https://github.com/olebedev/go-starter-kit)というよいサンプルがあるので、これを参考にした。

(ポイント1)ただし、goのvendoringでglideを使うのはやめて、depを使うことにした。glide公式が移行せよと言ってるっぽいので。

- Glide から Dep への移行を検討する
    - http://text.baldanders.info/golang/consider-switching-from-glide-to-dep/

んでvendoringして、ローカルでは動いた。

(ポイント2)`goapp serve`と`goapp deploy`を使っていたが、これは`dev_appserver.py`と`gcloud app deploy`に変えたほうがいいらしい。

- gcloudコマンドへの移行
    - https://shizuoka-go.appspot.com/entry/fcd7b533-78d5-4b21-8ecb-90b8f2a0d6f7

(ポイント3)だが、ファイル編集での自動再コンパイルがうまく動かない。どうやら、Mac環境で$GOPATH以下に10,000個ファイルがあると`google/appengine/tools/devappserver2/mtime_file_watcher.py`の中で制限にひっかかってしまう。

[ghq](https://github.com/motemen/ghq)を使っていて、.gitconfigには
```
[ghq]
  root = ~/dev/src
```
と書いており、$GOPATHも$HOME/devで、go以外の言語のプロジェクトもいっぱい突っ込んでいる。ので、$GOPATH配下に10,000ファイルを超えるのは避けがたい。

Linux環境で`google/appengine/tools/devappserver2/inotify_file_watcher.py`を使えば10,000ファイルでも平気なのかもしれないが、なるべくMacでVMなしでやりたいなあ。

でググったら、mtime\_file\_watcher.pyをいじる例がちらほら。えー直接いじりたくないよう。

と思ったら、`dev_appserver.py`に`--enable_watching_go_path`というオプションを発見。最近できたっぽい。`configure`みたいに`--disable_watching_go_path`も通るかと思いきやダメだったので、普通に`dev_appserver.py --enable_watching_go_path false`と動かすようにして解決。

(ポイント4)`gcloud app deploy`もうまく動かない。Go App Engineと`vendor`ディレクトリはハマりポイントらしく、こう解決してみた、というエントリがいくつかある。

- Google App EngineでGoを動かすときに知っておくべきこと（ソースコード・ビルド編）
    - http://motemen.hatenablog.com/entry/2016/11/gae-go-building
- 実践的なGAE/Goの構成について #golang #gcpja
    - https://qiita.com/koki_cheese/items/216fe73caf958db34aa2
- GAE/Go の勘どころ
    - https://speakerdeck.com/osamingo/go-falsekan-dokoro
- AppEngine for Go でのVendoring
    - https://www.freegufo.com/tech-blog/2016/gae-vendoring

`app.yaml`に`nobuild\_files`書くのはなんかやだったし、[gb](https://getgb.io/)入れるのもデカすぎなので、僕はこうした。

以下のようなディレクトリ構成をとって、`gopath/src`を`vendor`へのシンボリックリンクとし、``GOPATH=`pwd`/gopath gcloud app deploy``として、デプロイのときだけ$GOPATHを`gopath`にするようにした。ダサい。だが動いたぞ。

```
$GOPATH/src/github.com/gunyarakun/oreore-project
├── Gopkg.lock
├── Gopkg.toml
├── backend
│   ├── app.go
│   ├── app.yaml
├── gopath
│   └── src -> ../vendor
└── vendor
    ├── github.com
    │   └── ...
    └── google.golang.org
        └── appengine
```

google.golang.org/appengineをvendoringするのは意見分かれるところもあるが、ぼくは入れた。

フレームワークは[echo](https://github.com/labstack/echo)を使ったが、バージョン間の差異がけっこう大きい。ググったヤツは参考にせずに、公式ドキュメントとソースを見るとよい。

あとは、Google Cloud Datastoreで将来なにかハマりそうなくらいで、だいたいのハマりポイントは抜けた感じする。ハマったら随時追記しよ。
