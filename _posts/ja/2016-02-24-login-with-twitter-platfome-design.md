---
date: 2016-02-25 02:21:57
lang: ja
layout: post
tags: [tech]
title: Twitterアカウントで認証するAPIサーバをどう作るか
---
Twitterアカウントのみを使って認証を行い、HTTPS経由でWebブラウザのJavaScriptをターゲットにWeb APIを提供するサービスを考える。どのような方式があるか、考えてみた。2016年2月。

あまり人に読ませることを想定していない。OAuthも、1.0/2.0のクライアントを実装したことがあるくらい。OpenID/OpenID Connectとか知識ゼロ。

## Twitterアカウントのみを使って認証を行う

よく「認証と認可は違う！」とか、「OAuth 2.0での認可をもって認証とするのは危険である」という言説を見かける。斜め読みすると、そもそも↑でやろうとしていることが無理筋なのでは、という気がしてくるが、世の中にはTwitterで認証っぽいことやってるサイトいっぱいあるよね。あれって全部危険なの!?

という疑問を持ちつつ、[「OAuth 認証」を定義しよう](http://oauth.jp/blog/2016/02/25/oauth-authentication/)を読んだ。

> 「IdP (OAuth Server) 上の Identity 情報にアクセスする API へのアクセス権だけを OAuth Protocol に従って RP (OAuth Client) に渡しましょう。Identity 情報にアクセスする API は、まぁ JSON に user_id とか含めりゃだいたい動くでしょ。」っていうノリでできあがったのが、「OAuth 認証」です。

そう。これこれ。これやりたいんす。

OAuth 2.0のImplicit Flowで得られる認可をもって認証とするのではなく、OpenID Connectにきちんと対応しましょうね、という文章を読んだのだが、TwitterそもそもOAuth 1.0Aだし、そもそもOpenID Connectに対応してないし、今回の要件はImplicit Flow的というよりAuthorization Code Flow的な条件だし、その文書はfacebookやmixiとかにしか触れてないし…と悩んでいた。OpenID Connectは、OAuth 2.0上でIdentity Federationを行う標準化された1手法なのね。

というわけで、『[「OAuth 認証」を定義しよう]』を読んで、やりたいことそのものが致命的に破綻してはいないのだな、と理解した。あとは、実装上のセキュリティホールを作らないように気をつければいい。

また、Twitterには[Sign in with Twitter](https://dev.twitter.com/web/sign-in)という機能がある。これは、何らかの標準によるのではなく、Twitter独自の実装だ。ユーザ側がアクセス許可を出す画面について、一度許可を出していれば、2回目以降は画面を出さずにすむ。

今回はSign in with Twitterも有効にする。めんどくさくても毎回ユーザ側がアクセス許可を出すようにさせるのもありだろう。ここはトレードオフ。

漏らしてはいけない情報は、Consumer Secret。これが漏れるとアウト。

Sign in with Twitterを無効にして、X-Frame-Options対応ブラウザ側であれば、ユーザがアクセス許可を出すタイミングで気づけば大丈夫。でも普通気づかないと思うので結局Consumer Secret漏れるとアウト。

ここらへんは、[TwitterのOAuthの問題まとめ](https://gist.github.com/mala/5062931)を参考にした。

Consumer Secretが漏れちゃった場合、どんな影響があるか。漏洩に気づくことができるのか。影響を軽減できるか。これはまだ結論が出ていない。漏れたことに気づいたらすぐにConsumer Secretを再発行するのがよいが、でもそもそも漏れたことに気づかないんじゃね…という印象。

出来るとすれば、Consumer Secretの定期再取得くらい？ あとは、↑のサービスで「大事なとき用のパスワード」でも発行して、個人情報の閲覧・編集やお金払うときとかにはそれを入力してもらうとか？

## Web APIを上記認証のもと提供する

こんな選択肢あるじゃろ。選択肢のレベルが揃ってなくて排他的でないのは許せ。

- Cookieにsession idを保存する
- JWT: JSON Web Tokenを発行し、リクエストのAuthorizationヘッダに詰める
- OAuth 2.0 (+ OpenID Connect)のサーバを実装する

APIサーバにおいて、Cookieにsession idを保存するのは基本ナシ…という文章があったので、「なんでだろう…」と不思議がっていた。Cookieにsession idを入れることによるセッション管理って、枯れた技法であり、特に避けるべきと思ってなかったからだ。

その疑問は、[Cookies vs Tokens. Getting auth right with Angular.JS ](https://auth0.com/blog/2014/01/07/angularjs-authentication-with-cookies-vs-token/)を読んで解決した。

なるほど、クロスドメインがデフォルトで非対応(HTML/JavaScriptが別ドメインのCDN配信できねー)、session情報をストレージに入れることによる性能低下、CSRF対策がメンドイ、あたりがCookieを使うデメリットなのね。各種ヘッダを入れたり、なつかしのJSONPを使ったり、そういうめんどさがある。

んで、代替案としてJWT。サーバ側で鍵を使って改ざんをチェックできるトークンで、session情報そのものを含むことができる。ストレージレス!

JWT on Cookieも出来なくはないんだろうけど、上記のCookieのデメリット引きずるのであんまり意味ない。ストレージレスにはできる。

JWTは、暗号化はしなくて検証だけできるJWSと、暗号化もするJWEとがあるが、僕の用途ではJWSで十分。

JWTのマズいところは、サーバ側から「このトークンもう無効でっせ!!」と言えないところ。というわけで、トークンの有効期限を短くすることによって対処することにする。

OAuth 2.0のサーバを実装するという選択、とりあえずはない。登場人物として、ユーザー・僕らのAPIサーバ・そのAPIを使ったサービスの3者がいる。当初はAPIサーバと利用者が同一の予定なので、特にAPI利用者に応じてなにがしかのアクセス権限を制御する必要はない。

将来的にAPIをサードパーティーに解放するときに、JWTの利用は将来的なOAuthの利用を阻害しない。OAuth 2.0で得られるアクセストークンがJWTになってますよ、とかもできるわけで。できるよね？

というわけで、JWT使うことにした。

漏らしてはいけない情報は、JWTの秘密鍵。これ漏れるとJSON改ざん検出できない。ストレージとの合わせ技で改ざん検出は出来るんだろうけど、利点殺すしやりたくないよね。

## 全体の流れ

全てWebブラウザ上。HTTPS前提。

1. サービスのJavaScriptから、APIサーバの特定のエンドポイントを叩いて、認証開始する。開くべきURLがレスポンスで返ってくる。
2. 返ってきたURLを開き、ユーザがTwitter APIへのアクセスを許可する。
3. APIサーバのエンドポイントがコールバックされるので、内部でaccess tokenを取得する。JWTを作成し、JWTをquery stringに含んだ、サービスのURLにリダイレクトする。サービスのURLは事前に登録しておく。
4. サービス内のJavaScriptは、URL内のquery stringにJWTが含まれていたら、ローカルストレージに保存する。
5. クライアントは、APIサーバにリクエストを投げるたびにJWTをヘッダに詰める。
6. サーバはリクエストヘッダ内のJWTを検証し、APIのレスポンスを返す。

…でいける、かな？

## 守らなければいけないもの

- Twitterから発酵されたConsumer Secret
- JWTの秘密鍵

守り抜く。漏れた場合のダメージ軽減策は要検討。

なんか穴ありそうな気するんだけど、どうだろね？