---
date: 2016-12-29
lang: ja
layout: post
tags: [tech,aws]
title: AWSのフォーラムでコード片をキレイに貼る
---
AWS使っているけど、まだサービスインしていないので、サポート契約は結んでいない。というわけで、何かあったらフォーラムに書き込んでいる。

さて、Elastic Beanstalkにて、Amazon Linux v2.2.0ではOKだが、Amazon Linux v2.3.0ではNGとなる問題にぶち当たった。その内容をフォーラムに書こうとしたんだけど、コード片を貼ろうとしたら一部markupとして解釈されてしまって、見た目がよろしくない。

そこで、いろいろ試した結果、以下の２つのノウハウを得た。

- {noformat}で囲むと、その間はマークアップが解釈されない。ただし、改行なども無視されてしまうので注意が必要。
- {quote}で囲むと、blockquote扱いになる。

というわけで、以下のような文章を書けば、それなりにうまく反映されるようだ。

```
DNS lookup fails for EFS on Amazon Linux v2.3.0 but works well on v2.2.0

When I tried to upgrade the platform version of my elastic beanstalk environment from "64bit Amazon Linux 2016.09 *v2.2.0* running Multi-container Docker 1.11.2 (Generic)" to "64bit Amazon Linux 2016.09 *v2.3.0* running Multi-container Docker 1.11.2 (Generic)", the migration failed because lookup ing DNS with the name "fs-xxxx.efs.us-west-2.amazonaws.com" didn't work.

On "64bit Amazon Linux 2016.09 *v2.2.0* running Multi-container Docker 1.11.2 (Generic)", you can resolve the FQDN of EFS successfully.

{quote}
{noformat}[ec2-user@ip-10-0-0-75 ~]$ dig fs-xxxx.efs.us-west-2.amazonaws.com{noformat}

; <<>> DiG 9.8.2rc1-RedHat-9.8.2-0.37.rc1.49.amzn1 <<>> fs-xxxx.efs.us-west-2.amazonaws.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 48448
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;fs-xxxx.efs.us-west-2.amazonaws.com. IN A

;; ANSWER SECTION:
fs-xxxx.efs.us-west-2.amazonaws.com. 60 IN A 10.0.0.200

;; Query time: 2 msec
;; SERVER: 10.0.0.2#53(10.0.0.2)
;; WHEN: Thu Dec 29 07:45:46 2016
;; MSG SIZE  rcvd: 73
{quote}

On "64bit Amazon Linux 2016.09 *v2.3.0* running Multi-container Docker 1.11.2 (Generic)", resolving the FQDN name of EFS doesn't work.

{quote}
{noformat}[ec2-user@ip-10-0-2-4 ~]$ dig fs-xxxx.efs.us-west-2.amazonaws.com{noformat}

; <<>> DiG 9.8.2rc1-RedHat-9.8.2-0.47.rc1.51.amzn1 <<>> fs-xxxx.efs.us-west-2.amazonaws.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 11256
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 0

;; QUESTION SECTION:
;fs-xxxx.efs.us-west-2.amazonaws.com. IN A

;; AUTHORITY SECTION:
efs.us-west-2.amazonaws.com. 57	IN	SOA	ns-1536.awsdns-00.co.uk. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400

;; Query time: 0 msec
;; SERVER: 10.0.0.2#53(10.0.0.2)
;; WHEN: Thu Dec 29 07:35:00 2016
;; MSG SIZE  rcvd: 141
{quote}

Is there any additional action to resolve EFS FQDN names on Amazon Linux v2.3.0?
```

これで投稿しようとしたら、AWSのアカウントが新しく、フォーラムアカウントも新しいため、まだ投稿できない状態になって投稿できていない。

## AWSのフォーラムで使えるマークアップ一覧ほしい

なお、僕の他にもフォーラムでどんなマークアップができるかを試してみた人がいる。

Full list of forum markup options?
https://forums.aws.amazon.com/message.jspa?messageID=231309

だが、コメントにもあるように、彼がどんなマークアップをしたのかが投稿からだけではわからないのだ。さらに、bulletted listは無効だったりしている。

というわけで、公式で使えるマークアップ一覧があったらうれしいし、どこかに公開されてないですかね？
