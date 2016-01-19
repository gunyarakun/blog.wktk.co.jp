---
date: 2016-01-18 20:29:02
lang: ja
layout: post
tags: [tech]
title: JSON Schema Draft v.4の規格書を読む
---

2016年1月5日現在において、JSONを受け取り、返却するWeb APIを書くときに、人が作った規格に乗って楽をしようぜと考えた。

その過程で調べた、[JSON Schema](http://json-schema.org/)についてメモ書き。間違ってたらツッコミよろ。

## 概要

JSONの構造を記述する規格。構造の記述そのものもJSONで書かれる。

Draft v4現在では、JSON Schemaは以下の3つの規格の総体を指す。

- [JSON Schema Core](http://tools.ietf.org/html/draft-zyp-json-schema-04)
- [JSON Schema Validation](http://tools.ietf.org/html/draft-fge-json-schema-validation-00)
- [JSON Hyper-Schema](http://tools.ietf.org/html/draft-luff-json-hyper-schema-00)

そもそも提案された初期のJSON Schemaは、JSON Schema Core+JSON Schema Validationとほぼ同じ領域をカバーしていた。整理・発展の上3仕様に分割された。よって、JSON Schema Core+JSON Schema Validationにあたるものを単にJSON Schemaと呼ぶ場合がある。注意。

また、規格そのものではなく、この規格に基づいて書かれたJSONそのものもJSON Schemaと呼ばれる場合がある。まぎらわしいね！

## JSON Schema Core

JSONの構造と、各要素の型を指定できる。

ブログのエントリを表すJSONを考えよう。ブログは複数のエントリからなり、エントリは複数のコメントを持つとする。そのようなJSONの実例を示す。

<pre class="prettyprint">
{
  "entries": [
    {
      "id": 1,
      "title": "JSON Schema学んでみた",
      "name": "tasuku",
      "email": "tasuku-s-github@titech.ac",
      "icon": "http://blog.wktk.co.jp/favicon.ico",
      "image": "http://blog.wktk.co.jp/assets/image/json-schema.jpg",
      "text": "仕様書嫁",
      "comments": [
        {
          "id": 101,
          "name": "通りすがり",
          "email": "anonymous@example.com"
          "text": "もっと勉強しましょう。"
        },
        {
          "id": 102,
          "name": null,
          "email": null,
          "text": "エントリ長すぎでは"
        }
      ]
    },
    {
      "id": 2,
      "title": "ひとり暮らしの男性に、電気フライヤーのススメ",
      "name": "tasuku",
      "email": "tasuku-s-github@titech.ac",
      "icon": "http://blog.wktk.co.jp/favicon.ico",
      "image": "http://blog.wktk.co.jp/assets/image/electric-frier.jpg"
      "text": "http://blog.wktk.co.jp/archives/136 を百万遍嫁。",
      "comments": [
      ]
    }
  ]
}
</pre>

このようなJSONの構造に合致するJSON Schema(Coreの範囲内)の一例を示す。

<pre class="prettyprint">
{
  "type": "object",
  "properties": {
    "entries": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": {
            "type": "integer"
          },
          "title": {
            "type": "string"
          },
          "name": {
            "type": ["string", "null"]
          },
          "email": {
            "type": ["string", "null"]
          },
          "icon": {
            "type": "string"
          },
          "image": {
            "type": "string"
          },
          "text": {
            "type": "string"
          },
          "comments": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "id": {
                  "type": "integer"
                },
                "name": {
                  "type": ["string", "null"]
                },
                "email": {
                  "type": ["string", "null"]
                },
                "text": {
                  "type": "string"
                }
              }
            }
          }
        }
      }
    }
  }
}
</pre>

まあ、だいたい見たまんまというか、JSONの構造どおりに入れ子になって型が定義されているイメージ。Nullableな値は、null型もとりますよ、という指定を行う。

以下は、Core範囲内の細かい仕様。

- $から始まるプロパティ
  - $schema: JSON Schemaのバージョンを定義
  - $ref: スキーマ再利用のための参照。
    - #のあとが/から始まるJSON Pointerであれば、JSON Pointerが指すものを参照する
      - JSON Pointerとは、XMLでいうXPathみたいなもの
      - ex.) #/properties/entries
    - #のあとがJSON Pointerでなければ、ローアルなSchemaの中でIDが一致するものを参照する
      - ex.) #entries
- idというプロパティ
  - $refでの参照する際に指定する。
  - IDの値として、URIを指定する。 ex.) "id": "http://example.com/schemas/product.json#"
    - スコープの中のid/$refの値に対するURIのベースを指定する。HTMLのbaseタグみたいな感じ。
      - ex.) 祖先の要素でidが http://example.com/schemas/product.json だったら、"$ref": "person.json"は http://example.com/schemas/person.json を指す
      - ex.) 祖先の要素でidが http://example.com/schemas/product.json だったら、"id": "path/address.json#zipcode"は http://example.com/schemas/path/address.json#zipcode を指す
    - 大抵の場合は、JSON SchemaのルートObjectのidプロパティに#で終わるURLを指定し、それ以外のObjectのidプロパティには#で始まるSchema内ローカルなidを付与する。
      - このようにしておくと、"http://example.com/schema/schema.json#document_local_id" 的なURIでスキーマの要素がアクセスできる。
- definitionsというプロパティ
  - スキーマのテンプレ置き場
    - $refで参照できる
    - が、スキーマ定義そのものではない

細かい仕様を使ったSchemaの実例を示す。

"id"プロパティがスキーマ要素のIDなのか、対象とするJSONのObject値の中のidプロパティを指すのか、を注意して読もう。また、JSON内にはコメントを書くことができないが、説明上//記号以下はコメントとして扱う。

<pre class="prettyprint">
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "id": "http://blog.wktk.co.jp/schema/schema.json#",

  "definitions": {
    "name": {
      "id": "#name",
      // http://blog.wktk.co.jp/schema/schema.json#name
      // もしくは、JSON Pointerを使って
      // http://blog.wktk.co.jp/schema/schema.json#/definitions/name
      // で参照できる
      "type": ["string", "null"]
    },
    "email": {
      "id": "#email",
      "type": ["string", "null"]
    },
    "text": {
      "id": "#text",
      "type": "string"
    }
  },
  "type": "object",
  "properties": {
    "entries": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": { // これは、$refで参照できるidではない。idという名前のプロパティについてのschema。
            "type": "integer"
          },
          "title": {
            "type": "string"
          },
          "name": {
            "id": "#entry-author",
            "$ref": "#name"
          },
          "email": {
            "$ref": "#email"
          },
          "icon": {
            "type": "string"
          },
          "image": {
            "type": "string"
          },
          "text": {
            "$ref": "#text"
          },
          "comments": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "id": { // これは、$refで参照できるidではない。idという名前のプロパティについてのschema。
                  "type": "integer"
                },
                "name": {
                  "$ref": "#name"
                  // "$ref": "#/definitions/name" でもいい
                  // "$ref": "#entry-author" でもいい(結局#nameを参照する)
                  // "$ref": "#/properties/entries/items/properties/name"でもいい(結局以下略)
                },
                "email": {
                  "$ref": "#email"
                },
                "text": {
                  "$ref": "#text"
                }
              }
            }
          }
        }
      }
    }
  }
}
</pre>

## JSON Schema Validation

- Coreに追加する形で、値に対する制約をきつく、もしくはゆるやかにできる拡張
  - title/descriptionなどのメタ情報
  - デフォルト値(default)
  - Objectの必須プロパティ(required)
  - 最大値・最小値
  - 正規表現
  - 複数の値のうちのどれか(enum) ex.) "enum": ["red", "blue", null]
  - 複数のスキーマのAND/OR/NOT(allOf/anyOf/oneOf/not)
  - etc.
- allOf/anyOf/oneOf/notと$refの組み合わせで、参照したスキーマに手を加えたスキーマを作ることができる
  - これは実例みたほうが分かりやすい

というわけで、JSON Schema Core+ValidationでのSchemaの一例。一部の実装では、formatとか実装されてなかったりする。

<pre class="prettyprint">
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "id": "http://blog.wktk.co.jp/schema/schema.json#",

  "definitions": {
    "name": {
      "id": "#name",
      "pattern": "^[A-Za-z_]+$", // 正規表現もいける
      "type": ["string", "null"]
    },
    "email": {
      "id": "#email",
      "format": "email", // emailというフォーマットは仕様で定義されている
      "type": ["string", "null"]
    },
    "text": {
      "id": "#text",
      "minLength": 3, // 最低3文字は欲しいよね
      "maxLength": 1000000, // 100万文字まで!
      "type": "string"
    }
  },
  "type": "object",
  "properties": {
    "entries": {
      "type": "array",
      "description": "ブログエントリの一覧だよ",
      "items": {
        "type": "object",
        "description": "ブログエントリだよ",
        "properties": {
          "id": {
            "type": "integer"
          },
          "title": {
            "type": "string"
          },
          "name": {
            "id": "#entry-author",
            "$ref": "#name"
          },
          "email": {
            "$ref": "#email"
          },
          "icon": {
            "type": "string",
            "format": "uri" // format: uriも仕様で定義されている
          },
          "image": {
            "type": "string",
            "format": "uri"
          },
          "text": {
            "$ref": "#text"
          },
          "comments": {
            "type": "array",
            "maxItems": 100, // コメントは1エントリ100個まで
            "items": {
              "type": "object",
              "properties": {
                "id": {
                  "type": "integer"
                },
                "name": {
                  "$ref": "#name"
                },
                "email": {
                  "$ref": "#email"
                },
                "text": {
                  "$ref": "#text"
                }
              }
            }
          }
        }
      }
    }
  }
}
</pre>

このSchema、id, name, email, textの4つ組はセットで出てくるので、まとめられそうじゃね？ というわけで、allOfと$refを使ってまとめてみる。

<pre class="prettyprint">
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "id": "http://blog.wktk.co.jp/schema/schema.json#",

  "definitions": {
    "text_by_person": {
      "id": "#text_by_person",
      "type": "object",
      "properties": {
        "id": {
          "type": "integer"
        },
        "name": {
          "pattern": "^[A-Za-z_]+$",
          "type": ["string", "null"]
        },
        "email": {
          "format": "email",
          "type": ["string", "null"]
        },
        "text": {
          "minLength": 3,
          "maxLength": 1000000,
          "type": "string"
        }
      }
    }
  },
  "properties": {
    "entries": {
      "type": "array",
      "description": "ブログエントリの一覧だよ",
      "items": {
        "description": "ブログエントリだよ",
        "allOf": [ // 配列内の全ての条件を満たす
          {
            "$ref": "#text_by_person"
          },
          {
            "properties": {
              "title": {
                "type": "string"
              },
              "icon": {
                "type": "string",
                "format": "uri"
              },
              "image": {
                "type": "string",
                "format": "uri"
              },
              "comments": {
                "type": "array",
                "maxItems": 100,
                "items": {
                  "$ref": "#text_by_person"
                }
              }
            }
          }
        }
      }
    }
  }
}
</pre>

## JSON Schema CoreとValidationでできること

CoreとValidationで、JSON SchemaでJSONの構造や値の型・形式などが、Schemaに合致するかを検査することができる。

しかし、JSON Schemaそのものは、そのSchemaが表すリソースのURLや、リソースに対する情報取得・更新などの操作の情報を持たない。よって、APIサーバでのValidationに使いたい場合には、自らエンドポイントごとに、そしてリクエスト・レスポンスごとにJSON Schemaを定義する必要がある。

なお、JSON Schema CoreとValidationを理解するためには、仕様書の前に[Understanding JSON Schema](http://spacetelescope.github.io/understanding-json-schema/)を読むといい。

## JSON Hyper-Schema

ざっくり、URIごとに、そのURIにひもづくJSON Schemaを指定するもの。記述としては、JSON SchemaにURIをひもづける形式になる。

Schemaに、こんな要素が追加されます。

- links: SchemaにひもづくURIたちを指定する
  - 具体的には、LDO (Link Description Object)という形式の配列
  - href: Schemaになんらかの形でひもづくURIたち。正確にはURIのテンプレートたち。
    - 例) `"/{id}/comments"`
  - rel: Schemaが表すインスタンスと、リンク先との関係性を表す
    - 値は自分で決める
    - いくつかの値は、仕様で標準的な用途が決められている
      - self: インスタンス自身のURLを指定する
      - create: 新しいインスタンスを作成するリンクを表す
      - root: インスタンス内へのリンクを表す。hrefはフラグメントだけとなる。
      - etc.
  - title: タイトル
  - targetSchema: URIが返すJSONが従うべきSchema。他のSchemaで定義することもできる値ではある。
  - mediaType: image/pngとかtext/htmlとか。
  - method: GETとかPOSTとか
  - encType: リクエストに付与するパラメータのエンコード形式。application/x-www-form-urlencodedとか。
  - schema: リクエストに付与するパラメータのスキーマ。
- media: JSONの文字列にエンコードされたデータについて、元の情報を提供
    - binaryEncoding: どんなエンコーディング方式か。base64とか。
    - type: どんな形式か。image/pngとか。
- readOnly: 値が変更不可であることを示す。
- pathStart: あるURIから得られたインスタンスについて、複数のスキーマが定義されているときに、URIにpathStartが最長前方一致するスキーマだけが有効となる。

- 例: ブログのエントリを表すJSONのSchemaの場合。エントリそのもののデータに加えて、以下のような情報を付加できる
  - リンク
    - ブログエントリを表すJSONを返すURI
    - エントリについたコメント一覧を返すURL(GET)
    - エントリについてコメント一覧を検索するURLと、そのURLに渡すパラメータのSchema(パラメータ付きGET)
    - コメントを投稿するURLと、そのURLに渡すパラメータのSchema(POST)
    - エントリの画像(リンクとして)
  - media
    - エントリの画像(base64などで埋め込む場合)

実際、今までのブログのSchemaにこれらの情報を付加してみよう。こんな感じ。

<pre class="prettyprint">
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "id": "http://blog.wktk.co.jp/schema/schema.json#",

  // Hyper-Schemaのキモであるlinks要素
  "links": [
    // URLにスキーマを結びつける。
    // http://blog.wktk.co.jp/entries で取得できるJSONは、このSchemaに適合しますよ
    {
      "rel": "self", // この用途のrelはselfを指定すると仕様で決められてる
      "href": "/entries"
    },
    // エントリが持つコメント一覧へのリンク
    // 例) http://blog.wktk.co.jp/entries/123/comments
    {
      "rel": "comments", // このrelは適当に定義したもの。
      "href": "/entries/{id}/comments"
    },
    // コメントサーチ用のリンク GET
    // 例) http://blog.wktk.co.jp/entries/123/comments?searchTerm=検索ワード&itemsPerPage=50
    {
      "rel": "comments_search",
      "href": "/entries/{id}/comments",
      "schema": {
        "type": "object",
        "properties": {
          "searchTerm": {
            "type": "string"
          },
          // itemsPerPageは10の倍数で最低10, デフォルト20
          "itemsPerPage": {
            "type": "integer",
            "minimum": 10,
            "multipleOf": 10,
            "default": 20
          }
        },
        // searchTermは必須
        "required": ["searchTerm"]
      }
    },
    // コメントの投稿リンク POST
    // 例) http://blog.wktk.co.jp/entries/123/commentsに以下のようなJSONを投げると、コメントが付与できる
    // {
    //   "message": "とおりすがりの俺がコメント"
    // }
    {
      "rel": "create", // createは、何かインスタンスを作る操作のときに使う
      "title": "Post a comment",
      "href": "/entries/{id}/comments",,
      "method": "POST",
      "schema": {
        "type": "object",
        "properties": {
          "name": {
            "pattern": "^[A-Za-z_]+$",
            "type": ["string", "null"]
          },
          "email": {
            "format": "email",
            "type": ["string", "null"]
          },
          "text": {
            "type": "string"
          }
        },
        // コメントの内容たるtextは必須ですよ
        "required": ["text"]
      }
    },
    // エントリのトップ画像
    {
      "rel": "top_image",
      "href": "/entries/{id}/image",
      // MIME typeを指定できます
      "mediaType": "image/*"
    }
  ],

  "definitions": {
    // 略
  },
  "properties": {
    // 略
            "properties": {
              // 略
              // iconについて、今までURIで指定していたが、BASE64でエンコードしたPNG画像を直接埋め込んでみる
              "icon": {
                "type": "string",
                // mediaはHyper-Schemaで定義されている
                "media": {
                  "binaryEncoding": "base64",
                  "type": "image/png"
                }
              },
              // 略
            }
    // 略
  }
}
</pre>

## JSON Schema全体でできること

URIとSchemaの対応をlinksで記すことによって、JSONを受け取り返却するAPIサーバのリクエスト/レスポンスについて、形式的な情報を記すことができるようになった。

Hyper-Schemaまでの内容を利用して、以下のようなことができるミドルウェアがいくつかある。

### APIサーバでのバリデーション

  - JSON Hyper-Schemaで定義されたURIに対するrequest/responseが指定のSchemaに合致するJSONかどうかチェックする

### APIサーバのスタブ生成

  - Schemaに準じたランダムの値を返すAPI Webサーバを立てる

### APIドキュメントの生成

  - URIのエンドポイントごとに、どのようなリクエストのJSONを投げたら、どのようなレスポンスを得られるかのドキュメント
  - 実際にリクエストを投げるフォームを持ったHTMLドキュメントの生成

### APIクライアントの生成

  - URIのエンドポイントごとに、必要なパラメータを渡したら、レスポンスが返ってくるような関数の生成

## ミドルウェアの例

ミドルウェアの例はこれら。

- [Jdoc/Rack::JsonSchema by r7kamura](http://r7kamura.hatenablog.com/entry/2014/06/10/023433)
- [prmd/committee/heroics/schematic by Heroku](https://github.com/interagent/)

## JSON Schemaのデメリット

SchemaのJSONを書くのが煩雑。

- 対策1: http://jsonschema.net や https://github.com/kenchan/schemize でJSONの実例からスキーマのひな形を作ることができる
- 対策2: 複数のJSON Schemaをマージするツールがある。prmdなど。
- 対策3: YAMLのほうがJSONより書くのが楽ならば、いくつかのツールではYAMLを使ってJSON Schemaを出力することができる。prmdなど。

## JSON Schemaまとめ

- JSON Schemaは以下の3つの仕様の総体
  - JSON Schema Core: 型と構造
  - JSON Schema Validation: より詳細な値の形式と構造
  - JSON Hyper-Schema: URIにひもづいたJSON Schema
- できること
  - APIサーバのバリデーション
  - APIサーバのスタブ生成
  - APIドキュメントの生成
  - APIクライアントの生成
- デメリット
  - 書くのがめんどい

## 次回予告

次回は、[JSON API v.1](http://jsonapi.org/)について書く予定だよ。[HAL](http://stateless.co/hal_specification.html)とかとの比較も載せられる…といいな。
