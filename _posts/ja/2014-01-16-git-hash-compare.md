---
date: 2014-01-17 08:09:35 +0900
lang: ja
layout: post
tags: [tech]
title: gitで特定ディレクトリで特定のタグ/ブランチをディスク容量ケチって追う
---
gitで以下のようなことをやりたい。試しにスクリプト書いてみたんだが、どうもダサい感じがする。

入力値: リポジトリURL と タグ/ブランチ

指定のリポジトリURLから、特定のタグ/ブランチをcloneしてくる。すでにclone済みであって、clone済みのものが最新であればcloneしてこない。タグ・ブランチ名がバージョン番号っぽいものであれば、--depth 1を使って容量を削減する。

用途としては、モジュールを特定バージョンやブランチに固定したいが、ブランチ名の場合には履歴もちゃんととってそのモジュールの開発もできるようにしたい、というもの。

## 試しに書いたもの

<pre class="prettyprint linenums">
#!/bin/bash
BASE_URL="git@xxxx:user"

# $1 = repository_name, $2 = tag or branch

if [[ "$1" =~ / ]]; then
  echo "abune-" # For avoiding 'rm -rf /'
  exit 1
fi

git_dir="./$1/.git"
if [ -d "$git_dir" ]; then
  local_hash=$(GIT_DIR=$git_dir git rev-parse HEAD)
fi

remote_hash=$(git ls-remote $BASE_URL/$1.git $2^{} | cut -f1)
if [ -z "$remote_hash" ]; then
  remote_hash=$(git ls-remote $BASE_URL/$1.git $2 | cut -f1)
  if [ -z "$remote_hash "]; then
    echo "naiyo-"
    exit 2
  fi
fi

if [ "$local_hash" != "$remote_hash" ]; then
  if [[ $2 =~ ^v[0-9.]+$ ]]; then
    clone_flag="--depth 1"
  else
    current_branch=$(GIT_DIR=$git_dir git rev-parse --abbrev-ref HEAD)
    if [ "$current_branch" = "$2" ]; then
      # just pull
      pushd $1
      git pull origin $2
      popd
      exit 0
    fi
    clone_flag=""
  fi

  rm -rf $1
  git clone $clone_flag --branch $2 $BASE_URL/$1.git
  if [ $? -ne 0 ]; then
    echo "yabainjan"
  fi
else
  echo "nanmosen"
fi
</pre>

## ダサいところ

指定されたtagがannotated tagの場合にはコミットそのもののhash値を取るために、一回^{}を付けて聞いているのがイケてない。annotated tagでない場合は2回聞いちゃうので遅くなる。

<pre class="prettyprint">
git ls-remote git@xxx:user/rep v0.0.1^{commit}
</pre>

でうまくいくかと思ったけどダメだった。

<pre class="prettyprint">
git ls-remote git@xxx:user/rep v0.0.1*
</pre>

というのも考えたが、v0.0.1^{}と同時にv0.0.13などもひっかかってしまうのでダメ。

## こっちのほうがいい？

ローカルのほうですでにclone済みの場合には、

<pre class="prettyprint">
git describe --tag
</pre>

した結果現在指しているタグを取得する。次に、取得したタグを用いて、そのタグがannonated tagだった場合annotated tagのhash値を取る。具体的には、

<pre class="prettyprint">
git show-ref --tag -d $fetched_tag
</pre>

をして、一番下の1行を取得する。

これとリモートの指定されたhash値を比較する。これでリモートに対するコマンド発行数が1回に減らせそう。

ただ、もっとスマートに書けそうな気がするんだよなー。タグとブランチをちゃんと峻別したり、.gitディレクトリの中のファイルを見たりするとよさげか。というわけでブログで投げっぱなしジャーマン。ツッコミは[@gunyarakun](https://twitter.com/gunyarakun/)まで。
