---
date: 2010-12-27 11:31:57
lang: ja
layout: post
permalink: /archives/91
tags: [tech, google_app_engine, python]
title: Kay Frameworkで携帯電話対応サイトを作ってみる
wordpress_id: 91
---
Google App Engineの手習いに掲示板システムを書いている。使っているフレームワークは、Kay Framework。

この掲示板システムで、携帯電話対応をしたい。Djangoの場合にはdjango-bpmobileというapplicationがある。これをKay Frameworkに移植することを考える。自分が使いそうなところだけを…。

まずは軽くdjango-bpmobileを読む。middleware.pyから。django特有の部分をKay Frameworkに置き換えていけば大丈夫だろう的な読みの元に。

BPMobileMiddleware/BPMobileConvertResponseMiddlewareは、それほどDjangoに依存していなさげ。uamobile.detectに渡すdictを作ってあげたり、request.GET/request.POSTをrequest.args/request.formにしたり、response['content-type']をresponse.headers['content-type']にしたり、response.contentをresponse.dataに変えたりしたら動いた。よくテストしていないけど。

IPy/uamobileは全てapplicationフォルダ内に放り込んだ。こちらのほうがlibディレクトリよりapplication特有感が出ていいかなー、と思って。uamobile/cidr.pyはpkg\_resourcesからのimportをコメントアウトした。applicationフォルダ内にuamobileを入れると、uamobile配下のモジュール同士のimportに支障が出る。アプリケーションの\_\_init\_\_.pyで、sys.path.append(os.path.dirname(os.path.abspath(\_\_file\_\_))) をしてしのいだ。

BPMobileSessionMiddlewareは、移植が結構面倒くさそう。DjangoのSessionMiddlewareのクローンで、iモードIDからsessionのキーに変換する機能がついているものと認識。

iモードIDとセッションIDの結びつけには、キャッシュを使っているようだ。django.core.cache.cacheがそのインターフェース。Kay Frameworkの場合には、werkzeug.contrib.cache.GAEMemcachedCacheを使うとよさげか。

django-bpmobileでは、DoCoMoではすべてiモードIDを使う、という実装になっている。DoCoMoだけどCookieを食える端末も出てきたことだし、食える端末には食っていただこう。幸い、django-bpmobileが使っているUser-Agent解析ライブラリであるuamobileには、supports\_cookie()というメソッドがある。is\_docomo()なおかつnot supports\_cookie()の場合のみ、iモードIDを使うのがよいか。softbank端末の一部で、jpドメインでドメイン名が短いとCookie送ってくれないことがあるらしいが、仕事プロジェクトではないのでシカトしておこう。

kay.sessions.middleware.LazySession/SessionMiddlewareをコピペして、Cookieまわりの扱いのロジックをdjango-bpmobileから移植すればBPMobileSessionMiddlewareも動きそう。ためしに書いてみたが、僕の用途ではセッションはいらなかったんだった。

セッションはいらないが、ログインはさせたいお年頃。DoCoMoでCookieが食えない端末のみ、request.cookieにログイン用の情報をmiddlewareで仕込んであげれば、User.get\_current\_user()を騙せるのではないか。騙すためには、Cookieのキーが必要。開発環境ではgoogle.appengine.tools.dev\_appserver\_login.COOKIE\_NAMEであるところのdev\_appserver\_loginがキーなのだが、本番環境でCookieのキーを取る方法がわからない。responseを返すときに設定されるcookieを全て保存して、iモードIDに結びつけるという荒業も考えられる。これだったら、Cookieのキーは必要ない。
むしろ、セッションについてもCookieエミュレーションを行ったほうが、kayがもともと持つセッション機構を使えてよいのかもしれない。コピペしなくていいし。DoCoMoのCookie対応端末も増えていくだろうし。BPMobileDoCoMoCookieEmulationMiddleware的な。これ書こう、これ。←いまここ
