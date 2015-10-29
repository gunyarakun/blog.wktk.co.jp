---
date: 2015-10-29 01:03:23
lang: ja
layout: post
tags: [tech, ruby]
title: Rakeでgruntやgulpのようなファイル変更を監視してビルドしてMacで通知を出す
---

## やりたいこと

- 特定のディレクトリ以下のファイルに変更があったときに、rakeが走るようにしたい
- rakeが走ったあとに、Macで通知を出したい
- 複数のファイルが一挙に変更された際に、ファイル1個ごとでビルドが走らないようにしたい
- .git/index.lockとかが変更されたときに、ビルドが走らないようにしたい

## 既存のもの

[gulpにもmakeにも不満なWebデベロッパーためのRake（コンパイル・パターンマッチ・ファイル監視・通知）](http://qiita.com/doloopwhile/items/6088ad6c1753806da7c0#%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E5%A4%89%E6%9B%B4%E3%81%AE%E7%9B%A3%E8%A6%96%E9%80%9A%E7%9F%A5)というものがある。

- 複数のファイルが一挙に変更された際に、ファイル1個ごとでビルドが走ってしまう
- .git/index.lockとかが変更されたときに、ビルドが走ってしまう
- notify-sendがHomebrewにない

## 改造したヤツ

Rakefileこうなった。あんまりかっこよくない。パスとかの空白には弱そうだから適宜対処して欲しい。

<pre class="prettyprint linenums">
require 'mkmf'

TITLE = 'Super Slow Build Project'
GIT_REGEX = %r{/\.git/}
SLEEP_AFTER_BUILD = 10

PATH1 = 'sample'
PATH1 = 'path'

task :watch do |t|
  mac = (RbConfig::CONFIG['host_os'] =~ /\Adarwin[\d.]+\z/)
  unless mac
    puts 'Cannot use rake watch except MacOSX'
    exit(1)
  end
  unless find_executable('fswatch')
    `brew install fswatch`
  end
  IO.popen("fswatch '#{PATH1}' '#{PATH2}'", 'r') {|io|
    buffer = []
    loop {
      begin
        r = io.read_nonblock(1024)
        buffer << [r]
      rescue IO::WaitReadable
        lines, cr, rest = buffer.join('').rpartition("\n")
        buffer = [rest]
        build = lines.split("\n").any? {|line|
          GIT_REGEX.match(line).nil?
        }
        if build
          sh %{rake && rake notify_success || rake notify_error}
          sleep SLEEP_AFTER_BUILD
        end

        IO.select([io])
      end
    }
  }
end

task :notify_success do |t|
  notify('Build succeeded')
end

task :notify_error do |t|
  notify('Build ERROR')
end

def notify(message)
  puts message
  `osascript -e 'display notification "#{message}" with title "#{TITLE}"'`
end
</pre>
