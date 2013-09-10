---
layout: post
title: C言語でWebAppの開発に必要なN個のこと
lang: ja
tags : [tech, clang]
---

あるプログラミング言語で実際にWebAppを開発できるようになるまで、何が必要だろうか。言語仕様の習得は終えているとしよう。おそらく、最低限以下のような知識が必要だと思われる。とりあえずC言語について知っていることを書いた。

## パッケージマネージャ

まずライブラリの管理。モジュールをインストールし、可能であればバージョンを固定し、適切にロードする機能が必要だ。
C言語の場合は、静的リンクをすればすべてのモジュールがひとつのバイナリファイルにまとまる。バージョンも固定され、適切にロードも行われる。
動的リンクで読み込まれるライブラリを切り替えるのはめんどい。chrootとかで。

## アプリケーションサーバー

多くのWebサーバは、C言語もしくはC++言語で書かれている。すなわち、あなたが使っているWebサーバが、すぐにアプリケーションサーバとなる。
ライブラリのインターフェースとしては、Calling Conventionという仕様がある。世の中にある多くの高速なライブラリは、C言語のCalling Conventionに対応している。

IISというWebサーバには、ISAPIというWebサーバを拡張するためのAPIセットがある。[Apacheでも使えるぞISAPI](http://httpd.apache.org/docs/2.2/mod/mod_isapi.html)。すごいぞISAPI（棒読み）。おじさんはコレを仕事で書いたことがあるですよ。
しかし今でも使われているんだろうかISAPI。さすがに.netの何かにはなっていそうだが。

簡単なWebサーバであれば、[libuvを用いて書くことができる](https://gist.github.com/utaal/1195428)。だが、静的ファイルの配信などをする場合には、通常のWebサーバから行うことをオススメする。

## リクエストパラメーターの処理

各Webサーバの内部関数を用いるのが高速だ。

Apacheの場合。[ap_args_to_table()](http://ci.apache.org/projects/httpd/trunk/doxygen/group__APACHE__CORE__SCRIPT.html#gaed25877b529623a4d8f99f819ba1b7bd)か、
[ap_parse_form_data()](http://ci.apache.org/projects/httpd/trunk/doxygen/group__APACHE__CORE__DAEMON.html#ga9d426b6382b49754d4f87c55f65af202)を使おう。昔みたいに手でパースする必要はない。

lighttpdの場合。便利関数がない。こんなんでGETパラメータはparseできる。

<pre class="prettyprint linenums lang-c">
static int
split_get_params(array *get_params, buffer *qrystr) {
  size_t is_key = 1;
  size_t i;
  char *key = NULL, *val = NULL;

  key = qrystr->ptr;

  for (i = 0; i < qrystr->used; i++) {
    switch(qrystr->ptr[i]) {
    case '=':
      if (is_key) {
        val = qrystr->ptr + i + 1;
        qrystr->ptr[i] = '\0';
        is_key = 0;
      }

      break;
    case '&':
    case '\0': /* fin symbol */
      if (!is_key) {
        data_string *ds;
        /* we need at least a = since the last & */

        qrystr->ptr[i] = '\0';
        if (NULL == (ds = (data_string *)array_get_unused_element(get_params, TYPE_STRING))) {
          ds = data_string_init();
        }
        buffer_copy_string_len(ds->key, key, strlen(key));
        buffer_copy_string_len(ds->value, val, strlen(val));
        buffer_urldecode_query(ds->value);

        array_insert_unique(get_params, (data_unset *)ds);
      }

      key = qrystr->ptr + i + 1;
      val = NULL;
      is_key = 1;
      break;
    }
  }

  return 0;
}
</pre>

nginxの場合。[ngx_http_arg()](http://lxr.evanmiller.org/http/ident?i=ngx_http_arg)でよい。
[ngx_http_get_variable()](http://lxr.evanmiller.org/http/ident?i=ngx_http_get_variable)もあるが、領域を動的に確保するので開放しなければならない。
POSTデータを扱う場合には[form-input-nginx-module](https://github.com/calio/form-input-nginx-module)を参照のこと。

IISでISAPIを使う場合、[Discover ISAPI. Working with GET-POST data](http://www.codeproject.com/Articles/2570/Discover-ISAPI-Working-with-GET-POST-data)を参照のこと。MFCを使う版も使わない版もあるぞ。MFCという単語を久々にタイプするわけだが。

もちろん、Node.jsでも使われている[http-parser](https://github.com/joyent/http-parser)や、安心のkazuhoウェアであるところの[picohttpparser](https://github.com/kazuho/picohttpparser)も使うことができる。ツッコミありがとう[@mattn_jp](https://twitter.com/mattn_jp/status/377406804613156864)。

## ルーティング

気合い。

[PCRE](http://www.pcre.org/)や[鬼車](http://www.geocities.jp/kosako3/oniguruma/index_ja.html)くらいは欲しくなるかもしれない。

## データベース

なぜだかよく分からないが、多くのデータベースは、C言語から呼び出すことができるドライバを標準で用意している。
O/R Mapperだって？頑張ってstructにマップしよう。

## ビューのレンダリング

HTMLについて。
[ClearSilver](http://www.clearsilver.net/)というものがあるが、今となってはオススメしない。
Googleの検索トップ画面でも使われていた[Ctemplate](http://google-ctemplate.googlecode.com/svn/trunk/doc/guide.html)を使おう。
[libxml2](http://www.xmlsoft.org/)という男気あふれる選択もよいだろう。

JSONについて。
[picojson](https://github.com/kazuho/picojson)はオシャレ言語C++で書かれているので使えない。
[nxjson](https://bitbucket.org/yarosla/nxjson/src)でも使っておこう。

## テストフレームワーク

[Cutter](http://cutter.sourceforge.net/)を使っておこう。作者も日本人だし。

## WAF

C言語からは、自由に言語処理系を呼び出すことができる。
例えばRubyを呼び出せば、Rackに準拠したRuby on RailsやSinatraなどのフレームワークが使える。
PythonもPerlも自由自在。つまりは最強なのだ。
組み込みやすいLuaやPythonやmrubyなんかを呼び出すのがよいだろう。

もし言語の呼び出し部分が面倒であれば、FastCGIプロトコルを実装することをオススメする。WSGI実装/Rack/PSGI実装/PHPの全てにおいてFastCGIプロトコルに対応している。

## まとめ

以上。しかし、メンテナンス性が著しく低下するので、他の言語を採用してほしい。

(元ネタ: [PerlでWebAppの開発に必要なN個のこと](http://d.hatena.ne.jp/gfx/20130909/1378741015))
