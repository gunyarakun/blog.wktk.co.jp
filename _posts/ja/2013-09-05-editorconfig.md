---
layout: post
title: EditorConfigがなかったら、心がグシャグシャになってしまうなぁ。
lang: ja
tags : [tech]
---
昨今、プロジェクトごとに言語のバージョンや、各種設定、ライブラリを使い分けることが当たり前となってきている。

上記のような使い分けは、Visual Studio/Eclipse/Xcodeなど、IDEにひもづいたプロジェクトファイルがある環境では当たり前だった概念ではある。プロジェクトディレクトリトップに.xxxconfig的なファイルを置くという手法がデファクトスタンダードとなったことによって、コマンドライナー(ライフライナー的)たちの間でもそういった文化が広がりつつあると捉えている。

プログラミング言語について、Rubyのrvm/rbenvのように、複数のバージョンの実行系を気軽に切り替えられるようになってきている。また、Rubyのrvmでは.rvmrc、rbenvでは.rbenv-versionというファイル名で設定を記述していたものを、両者とも.ruby-versionというファイル名で設定が参照できるようになるなど、設定ファイルそのものの共通化という方向性がある。

プログラミング言語のライブラリも、以前はシステムワイドにインストールしていたものを、特定の名前をつけたサブセットにインストールしたり、プロジェクト直下のディレクトリにインストールすることも増えてきた。virtualenvやBundlerやcpanm/Carton/local::libなど、各言語とも似たような概念をサポートするライブラリが登場しつつある。

## エディタの設定もプロジェクトごとに変えたい

上記のような状況のなか、エディタの設定についてはどうだろうか。インデントの種類や幅などはプロジェクトごとに統一したい。従来は、VimのmodelineやEmacsのFile Variablesなど、ファイルの先頭や末尾に特定の記述をすることによって設定を行っていた。しかし、ファイルごとに設定するのは面倒であるし、Vim/emacsの両方の設定を書くのも冗長だ。

また、近年はSublime Textなどの新興エディタもあるし、そもそも上記のようなIDEを使って編集することもあり得る。よって、特定のプロジェクト配下においてエディタ間をまたがった設定を共有できればうれしいな、と思うのは自然な発想だ。

エディタ・IDE間で設定を共有できる方法ってあるの？

あるんです。それが[EditorConfig](http://editorconfig.org/)。

## EditorConfigとは

[EditorConfig](http://editorconfig.org/)とは、複数のエディタ・IDEで共通の編集設定をするための仕様をとりまとめるプロジェクトである。設定ファイルのフォーマットと、そのファイルを読み込んでエディタ・IDEの挙動を替えるプラグインとを提供している。

これがあれば、スペースでインデントしてるんだけど、スペースが8個集まったらハードタブになっているようなファイルなどを駆逐することができるのだ。いえー

.travis.ymlと.editorconfigをあなたのプロジェクトトップに置いて、早速オシャレっぷりをアピールしましょう。

## 対応エディタ・IDE

エディタやIDEに導入するプラグインは、[EditorConfigのプラグインダウンロード](http://editorconfig.org/#download)からどうぞ。

![EditorConfigのプラグインダウンロードアイコン](/assets/images/entry/2013-09-05/editorconfig-download-plugin-icon.png)

アイコンがゆるくてかわいいですね。Eclipseがないのは、仕組み上しょうがないのかな。JetBrains系は結構充実してる。

## 設定ファイル.editorconfigのフォーマット

設定ファイルはこんな感じに記述する。.editorconfigという名前でプロジェクトトップのディレクトリに放り込んでおけばよい。

<pre class="prettyprint linenums lang-ini">
# EditorConfig is awesome: http://EditorConfig.org

# top-most EditorConfig file
root = true

# Unix-style newlines with a newline ending every file
[*]
end_of_line = lf
insert_final_newline = true
charset = utf-8

# 4 space indentation
[*.py]
indent_style = space
indent_size = 4
trim_trailing_whitespace = true
insert_final_newline = false
trim_traling_whitespace = true
max_line_length = 120

# Tab indentation (no size specified)
[*.js]
indent_style = tab

# Indentation override for all JS under lib directory
[lib/**.js]
indent_style = space
indent_size = 2
</pre>

なんかあんまり説明いらない感じですね。直感的です。

[末尾スペースを憎む宗教に入っていた](http://d.hatena.ne.jp/tasukuchan/20070816/1187246177)僕としては、trim\_trailing\_whitespaceがあるのがうれしい。末尾スペースの自動削除です。

なお、一部のプラグインは、一部の設定値について反映することができない。例えば、行の最大の長さであるmax\_line\_lengthはVimでのプラグインしかサポートしていないようだ。

将来的には、indent\_brace\_styleのような値もサポートするらしい。ブロックが中括弧系言語で、どのようにブロックを配置するかという値だ。

## 余談

EditorConfigは隣席のエンジニアから教えてもらった。彼曰く、「EditorConfigのキャラクターはGo langのキャラクターと似ていてゆるくてよい」ということらしい。

![EditorConfigのマスコットネズミ](/assets/images/entry/2013-09-05/editorconfig-character.png)

[真面目にいろんな設定について紹介されている方がいるので](http://dev.hageee.net/21)、そちらも参照のこと。
