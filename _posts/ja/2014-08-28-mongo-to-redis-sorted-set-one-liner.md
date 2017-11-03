---
date: 2014-08-29 10:04:31 +0900
lang: ja
layout: post
tags: mongodb redis
title: MongoDBからRedisのsorted setにデータを移すワンライナー
---
リカバリで必死こいて書いた。

<pre class="prettyprint linenums">
./mongoexport --query '{ condition: true }' \
  -h mongo.example.com --port 12345 \
  -d database -c collection \
  -u user -p password \
  --fields score,_id \
  --csv | \
  ruby -pe 'def gen_redis_proto(*cmd); proto = ""; proto << "*"+cmd.length.to_s+"\r\n"; cmd.each{|arg| proto << "$"+arg.to_s.bytesize.to_s+"\r\n"; proto << arg.to_s+"\r\n"}; proto; end; a = $_.chomp.split(","); $_ = gen_redis_proto("ZADD", "SORTED_SET", a[0], a[1])' | \
  redis-cli -h redis.example.com --pipe
</pre>
