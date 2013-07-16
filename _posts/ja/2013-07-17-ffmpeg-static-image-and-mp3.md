---
layout: post
title: FFmpegを使って静止画とmp3からH.264動画を作る
lang: ja
tags : [image]
---
MacでHomebrew使って入れたFFmpegで実験。

コンテナがMKVでよければ。

<pre class="prettyprint linenums lang-bash">
> ffmpeg -i input.mp3 -loop 1 -i input.jpg -vcodec libx264 -preset slow -crf 20 -threads 0 -acodec copy -shortest output.mkv
</pre>

ニコニコ動画にアップする場合にはMP4などに包む。なお、libfaacはサンプリングレートが低すぎると怒られるので、ar 24000を設定した。必要なければいらないす。

<pre class="prettyprint linenums lang-bash">
> ffmpeg -i input.mp3 -loop 1 -i input.jpg -vcodec libx264 -preset slow -crf 20 -threads 0 -acodec libfaac -shortest -ar 24000 output.mp4
</pre>
