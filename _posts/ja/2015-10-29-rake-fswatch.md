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
- 複数のファイルが一挙もしくは短い間に変更された際に、ファイル1個ごとでビルドが走らないようにしたい
- .git/index.lockとかが変更されたときに、ビルドが走らないようにしたい
- Rubyのfswatchをわざわざ入れなくても、コマンドのfswatchが入っていれば走るようにしたい
- ビルド中にまたファイルに変更があったら、ビルドを即中止して新しいビルドを走らせたい

## 既存のもの

[gulpにもmakeにも不満なWebデベロッパーためのRake（コンパイル・パターンマッチ・ファイル監視・通知）](http://qiita.com/doloopwhile/items/6088ad6c1753806da7c0#%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E5%A4%89%E6%9B%B4%E3%81%AE%E7%9B%A3%E8%A6%96%E9%80%9A%E7%9F%A5)というものがある。

- 複数のファイルが一挙もしくは短い間に変更された際に、ファイル1個ごとでビルドが走ってしまう
- .git/index.lockとかが変更されたときに、ビルドが走ってしまう
- ビルドを中止してくれない
- notify-sendがHomebrewにない

## 改造したヤツ

Rakefileこうなった。あんまりかっこよくない。パスとかの空白には弱そうだから適宜対処して欲しい。pid一周誤爆kill気にしないねー。

<pre class="prettyprint linenums">
require 'mkmf'

APP_NAME = 'Super Slow Build Project'

IGNORE_REGEX = %r{/\.git/}
WAIT_BUFFER_SECOND = 2.0

task :watch do |t|
  mac = (RbConfig::CONFIG['host_os'] =~ /\Adarwin[\d.]+\z/)
  unless mac
    puts 'Cannot use rake watch except MacOSX'
    exit(1)
  end
  unless find_executable('fswatch')
    `brew install fswatch`
  end
  IO.popen("fswatch TARGET_PATH1 TARGET_PATH2", 'r') {|io|
    buffer = []
    pid = nil
    last_load = 0
    loop {
      begin
        r = io.read_nonblock(1024)
        buffer << [r]
        last_load = Time.now.to_f
      rescue IO::WaitReadable
        if Time.now.to_f - last_load < WAIT_BUFFER_SECOND
          sleep 0.5
          retry
        end

        lines, cr, rest = buffer.join('').rpartition("\n")
        buffer = [rest]
        build = lines.split("\n").any? {|line|
          IGNORE_REGEX.match(line).nil?
        }
        if build
          if pid
            Process.kill(9, pid)
          end
          pid = fork {
            sh %{rake} do |ok, res|
              if ok
                notify('Build succeed')
              else
                notify('Build ERROR')
              end
            end
          }
        end

        IO.select([io])
      end
    }
  }
end

def notify(message)
  puts message
  `osascript -e 'display notification "#{message}" with title "#{APP_NAME}"'`
end
</pre>
