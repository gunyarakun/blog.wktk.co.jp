---
date: 2014-12-17 16:21:41
lang: ja
layout: post
tags: [tech, webgl]
title: 生WebGL入門でWebGLに入門する(第1回)
---
「[生WebGL入門:初音ミクの美麗3Dモデルを表示する](http://nmi.jp/archives/582)」という記事がある。好評のようだ。3Dはレイトレーシングしか知らない、DirectXはDicect2D専門だったおっさんとしては、3DとWebGLを一緒に学べるチャンスだ。ぜひぜひ学習してみよう。

## 準備

準備がいきなりハードル高い。Blenderを入れないといけないのか。後回しにしよう。

「人が読める形式のOBJ形式」という説明が出てくるが、OBJ形式とはどんな形式だろう。OBJという拡張子のファイルはだいたい（普通の）人が読めないバイナリ形式のイメージがある。ひっかかるが読み飛ばす。

で、あにまさ式ミクをダウンロードして、OBJ形式にコンバートしておく必要があるらしい。あにまさ式ミクのモデルデータは、MMDのパッケージ内に入っているとのこと。

「MMD ダウンロード」でGoogle検索して1番目に出てきたページ、「[VPVP Wiki](http://www6.atwiki.jp/vpvpwiki/pages/187.html)」から、「[VPVP](http://www.geocities.jp/higuchuu4/)」へジャンプ。1.1 MikuMikuDanceの項からダウンロードリンクをクリックして、[MikuMikuDance v2.02](http://www.geocities.jp/higuchuu4/pict/MikuMikuDance_v202.zip)を取得。zipを解凍してpmdという拡張子のファイルを探すも見つからず。Dataというフォルダの中身がそれっぽそうなのだが。

さきほどの[VPVP WikiにあるFAQページ](http://www6.atwiki.jp/vpvpwiki/pages/330.html)を見てみると、VPVPではMikuMikuDanceの3つのバージョンが公開されていて、MikuMikuDance（DirectX9 Ver）とMikuMikuDance (Multi-Model Edition)しかpmdファイルに対応していないらしい。

DirectX9 Verをダウンロードしようとしたが、それより新しい64bitOS Verが出ているようなので、そちらをダウンロード。解凍して、UserFile/Model/初音ミク.pmdを発見。ようやく見つけたぞ!!!

Cheetah3Dは持っているので、それでpmd->obj変換できないかなー…とググると、「Cheetah3Dで読み込むためにBlenderを使ってpmdからobjに変換しよう」という記事を見つけて絶望する。Blenderを入れる時が来たか。

いつもの僕なら、ここで挫折していたんだけど、この記事を書いているので続行。板ポリとか出したあとモチベーション高いままダウンロードとかしないと挫折しそう。

「Mac Blender」で検索して、1件目の[ダウンロードサイト](http://wiki.blender.org/index.php/Doc:JA/2.6/Manual/Introduction/Installing_Blender/Mac)を見る。2.72 64bit OS版をダウンロード。こちらはダウンロードしたzipを解凍したらアプリケーションが出てきた。

Blenderを起動して、「初音ミク.pmd」をとりあえずDrag & Drop。カーソルが「＋」になっているからなんかうまくいくのでは!? ダメだった…

「Blender pmd obj 変換」でGoogle検索。何件か見たところ、Blender2pmdというアドオンを入れて、データをインポートする必要があるらしい。

ググって見つけた[Blender2pmd配布ダウンローダ](http://u7.getuploader.com/Yjo_oi_Neg/)からBlender2pmdをダウンロード…しようと思ったけど、Blrnder2pmdではなく、Blender2pmxというものもある。どっちをダウンロードしたらいいんだろう。ダウンロードサイトで表示されている日時に年が入っていないので、どれが最新か分からない。

「pmx」でGoogle検索したところ、[解説記事](http://dic.nicovideo.jp/a/pmx)を発見。pmdの次世代フォーマットらしい。つまり、Blender2pmdよりBlender2pmxのほうが新しいバージョンと推察される。なので、Blender2pmxの「i1.26 e1.25」とコメントされているものをダウンロード。解凍して出てきたreadme.txtに基づいて、フォルダをBlenderのaddonsフォルダに入れる…らしいが、Blenderのaddonsフォルダはどこにあるんだろう。

「Mac Blender addons」で検索すると、2012.12.10の情報では、「/Applications/Blender/blender.app/Contents/MacOS/バージョン/scripts/addons」らしい…が見つからない。自分でaddonフォルダを探してみると、どうやら「/Applications/Blender/blender.app/Contents/Resources/バージョン/scripts/addons」が最新の情報のようだ。先ほどのBlender2pmxを解凍したフォルダをそこに突っ込む。

次は、「Blenderのユーザー設定にあるAddonsから、Import-Export：MMD PMX Formatを探してチェックを入れる」そうだ。

Blenderを再起動して、左上の「i」のアイコンをクリック。そこにある「User Preferences」をクリック。むむむ…　「i」のアイコンが変わり、Save User Settingsというボタンは出てきたけど、設定項目などが見当たらない。

「blender addons enable」でGoogle検索。[1件目のサイト](http://wiki.blender.org/index.php/Doc:2.6/Manual/Extensions/Python/Add-Ons)によると、User PreferenceはFileメニューの中にあると書いてある。

左上の「スパナ」のアイコンをクリック。そこにある「Info」をクリックして、「i」のアイコンに戻す。Fileをクリックすると…、ここにもあった、「User Preferenfces」！ クリックすると、設定ができそうなWindowが開いた。いえー！

Addonsタブを開いて、Import-Export：MMD PMX Formatを発見。チェックを付けて有効化する。「Save User Settings」ボタンを押してWindowを閉じる。

Fileメニューを再度開いて、Importを見ると… PMX File for MMDがある！ あ、でも、対応している拡張子は「.pmx」としか書いていない。

![pmxしか書いてない](/assets/images/entry/2014-12-17/pmx_only.png)

これは、pmdとpmxでImporterが分かれているというパターンでは!? あーBlender2pmxではなくてBlender2pmdをダウンロードしておけばよかった…

ヤケクソだ、試しに開いてみよう。

![どちらもいけるのでは?](/assets/images/entry/2014-12-17/pmd_pmx_ok.png)

お…拡張子の表現が、*.pm[dx]になっている。これはpmdファイルもインポートできるのでは!?
試しにモデルのフォルダに行ってみよう…

![文字化け!](/assets/images/entry/2014-12-17/obaq.png)

ぎゃー文字がお化けのQ太郎ワンワンパニック!!! とりあえず文字が化けてないMEIKOを開いてみるか…

![エラー](/assets/images/entry/2014-12-17/meiko_load_error.png)

ううう。エラー。

元記事に戻ってみる。「PMD形式は標準ではサポートされていないので、まずPMDのimportをサポートするプラグインをインストールし、それを使ってインポートします。確か自分が使ったのはこれだったと思いますが、読み込みができればどれを使っても大丈夫です。」という文面の「これ」にリンクが。

リンク先を開くと、どうやら文字化けは設定で直せるらしい。なので、User PreferencesのSystemタブを開くと…ない！ない！ローカライズというチェックが。そこにInternational Fontsというチェックがあったので、試しにつけてみたら、同じようなインターフェースが出てきた。International Fontsとローカライズは違う気がするが、メニューの中身からするとローカライズのほうが適切だと思う。日本語設定をし、インターフェース・ツールチップ・新規データも日本語翻訳とする。

すると…文字化け治った！いぇい。

![文字化け解消](/assets/images/entry/2014-12-17/obaq_fix.png)

試しにMEIKOを開くと…エラー。初音ミクを開くと…エラー。万事休す。

というわけで、元記事の作者のtkihiraにヘルプを求め中。理想としては、ミクでなくてもよいのでobjファイルが提供されているとうれしいです…

## 第1回まとめ

- 準備ですでにつまづく
