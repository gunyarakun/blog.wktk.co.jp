---
layout: !binary |-
  cG9zdA==
status: !binary |-
  cHVibGlzaA==
published: true
title: Debian/Ubuntuで、nginx + FastCGIでWordPressを高速に動かす
author: !binary |-
  dGFzdWt1
author_login: !binary |-
  dGFzdWt1
author_email: !binary |-
  YmxvZ0B3a3RrLmNvLmpw
wordpress_id: 184
wordpress_url: !binary |-
  aHR0cDovL2Jsb2cud2t0ay5jby5qcC8/cD0xODQ=
date: 2011-06-02 12:23:59.000000000 +09:00
categories:
- 技術メモ
- PHP
- WordPress
tags: []
comments: []
---
<p>昨日、ブログのエントリをアップしてTwitterで宣伝したら、即サイトが落ちた。ダサすぎる。というわけで、Apache2を廃し、nginx(proxy) + nginx(FastCGI)の構成でWordPressを動かす設定をする。サーバはAmazon EC2。</p>
<p>この構成を試す前に行ったnginx(proxy) + Apache2(mod-php)は簡単に性能を上げることができた。しかし、nginx + nginxではどうもうまくキャッシュしてくれない。HTTPヘッダを見てみると、
<pre>
Expires: Thu, 19 Nov 1981 08:52:00 GMT
Cache-Control: no-store, no-cache, must-revalidate, post-check=0, pre-check=0
Pragma: no-cache
</pre>
とか出てるし！Expiresに入っている日付から、PHPのsession.cache_limiter = nocache由来のヘッダだとわかる。</p>
<p>なんでPHP由来なのに、Apache経由では同じヘッダが出なかったのか。それはWordPress内の.htaccessでExpiresが設定され上書きされているからのようだ。</p>
<p>とりあえず、index.phpへのアクセスにexpires 2h;をつけたらproxy側のnginxでキャッシュされるようになった。しかし、更新時に2hもコンテンツが保持されるのはイヤだ。というわけで、<a href="http://wordpress.org/extend/plugins/nginx-manager/" target="_blank">NGINX Manager</a>を使って明示的にpurgeするようにする。</p>
<p>バックエンドをnginxにしたのは、メモリ容量が限られたEC2のsmall instanceで動かしたいから。通常の場合はApacheにしたほうが無難。そうしないと変なハマりかたをする。.htaccessを使うApache依存のモジュールもあるし。</p>
<p><br />
sudo aptitude install nginx spawn-fcgi php5-cgi php5-mysql mysql-server<br />
cd /etc/nginx/sites-available<br />vim wktk-blog</p>
<pre># wktk blog
server {
  listen 8080;

  root /home/tasuku/blog_wktk;
  # server_name blog.wktk.co.jp;

  location / {
    index index.php;
    if (-f $request_filename) {
      expires 14d;
      break;
    }
    if (!-e $request_filename) {
      rewrite ^(.+)$ /index.php?q=$1 last;
    }
  }
  location ~ \.php$ {
    include       fastcgi_params;
    fastcgi_pass  127.0.0.1:9001;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param PATH_INFO $fastcgi_path_info;
    fastcgi_param SERVER_PORT 80;
    fastcgi_param SERVER_NAME blog.wktk.co.jp;
    expires 2h;
  }
}
</pre>
<p>vim wktk-blog-proxy</p>
<pre># wktk blog reverse proxy

proxy_cache_path  /var/cache/nginx levels=1:2 keys_zone=czone:180m max_size=512m inactive=120m;
proxy_temp_path   /var/tmp/nginx;
proxy_cache_key   "$scheme://$host$request_uri";
proxy_set_header  Host               $host;
proxy_set_header  X-Real-IP          $remote_addr;
proxy_set_header  X-Forwarded-Host   $host;
proxy_set_header  X-Forwarded-Server $host;
proxy_set_header  X-Forwarded-For    $proxy_add_x_forwarded_for;
proxy_buffers     32 16k;

upstream backend {
  ip_hash;
  server 127.0.0.1:8080;
}

server {
  listen 80;

  # root /home/tasuku/blog_wktk;
  server_name blog.wktk.co.jp;

  location /wp-admin { proxy_pass http://backend; }
  location ~ .*\.php { proxy_pass http://backend; }

  expires off;

  set $do_not_cache 0;

  location / {
    set $mobile 0;
    if ($http_user_agent ~* '(DoCoMo|J-PHONE|Vodafone|MOT-|UP\.Browser|DDIPOCKET|ASTEL|PDXGW|Palmscape|Xiino|sharp pda browser|Windows CE|L-mode|WILLCOM|SoftBank|Semulator|Vemulator|J-EMULATOR|emobile|mixi-mobile-converter)') {
      set $mobile 1;
    }
    if ($http_user_agent ~* '(iPhone|iPod|Opera Mini|Android.*Mobile|NetFront|PSP|BlackBerry)') {
      set $mobile 2;
    }
    if ($http_cookie ~* "comment_author_[^=]*=([^%]+)%7C|wordpress_logged_in_[^=]*=([^%]+)%7C") {
      set $do_not_cache 1;
    }
    proxy_no_cache     $do_not_cache;
    proxy_cache_bypass $do_not_cache;
    proxy_cache        czone;
    proxy_cache_key    "$scheme://$host$request_uri$is_args$args$mobile";
    proxy_cache_valid  200 20m;
    proxy_cache_valid  404 5m;
    proxy_pass         http://backend;
  }

  location ~* \.(jpg|png|gif|jpeg|css|js|swf|pdf|ppt|pptx)$ {
    proxy_cache_valid  200 120m;
    expires            864000;
    proxy_cache        czone;
    proxy_pass         http://backend;
  }

  location  ~* \/[^\/]+\/(feed|\.xml)\/? {
    if ($http_cookie ~* "comment_author_[^=]*=([^%]+)%7C|wordpress_logged_in_[^=]*=([^%]+)%7C") {
      set $do_not_cache 1;
    }
    proxy_no_cache     $do_not_cache;
    proxy_cache_bypass $do_not_cache;
    proxy_cache        czone;
    proxy_cache_valid  200 60m;
    proxy_pass         http://backend;
  }
}
</pre>
<p>vim /etc/init.d/spawn-fcgi-php</p>
<pre>#! /bin/sh
### BEGIN INIT INFO
# Provides:          spawn-fcgi-php
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start/stop php-cgi using spawn-fcgi
# Description:       Start/stop php-cgi using spawn-fcgi
### END INIT INFO

# Author: Richard Laskey <me@rlaskey.org>
# for more information, please visit http://rlaskey.org/

PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="php-cgi via spawn-fcgi"
NAME=spawn-fcgi-php
PIDFILE=/var/run/$NAME.pid
DAEMON=/usr/bin/spawn-fcgi

# you can change the arguments for spawn-fcgi here:
        # -C 3 implies three children processes
        # -a 127.0.0.1 binds to the loopback device
        # -p XYZ sets the the listening port to XYZ
        # -u and -g set the user/group the process runs as
        # -f is deprecated; -- <command></command> is the preferred syntax
DAEMON_ARGS="-C 3 -a 127.0.0.1 -p 9001 -u www-data -g www-data -P $PIDFILE -- /usr/bin/php-cgi"
SCRIPTNAME=/etc/init.d/$NAME

# Exit if the package is not installed
[ -x "$DAEMON" ] || exit 0

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] &amp;&amp; . /etc/default/$NAME

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.2-14) to ensure that this file is present
# and status_of_proc is working.
. /lib/lsb/init-functions

#
# Function that starts the daemon/service
#
do_start()
{
        # Return
        #   0 if daemon has been started
        #   1 if daemon was already running
        #   2 if daemon could not be started
        # --exec has been replaced by --startas
        start-stop-daemon --start --quiet --pidfile $PIDFILE --startas $DAEMON --test > /dev/null \
                || return 1
        start-stop-daemon --start --quiet --pidfile $PIDFILE --startas $DAEMON -- \
                $DAEMON_ARGS \
                || return 2
        # Add code here, if necessary, that waits for the process to be ready
        # to handle requests from services started subsequently which depend
        # on this one.  As a last resort, sleep for some time.
}

#
# Function that stops the daemon/service
#
do_stop()
{
        # Return
        #   0 if daemon has been stopped
        #   1 if daemon was already stopped
        #   2 if daemon could not be stopped
        #   other if a failure occurred
        # removed --name $NAME since the running process is not spawn-fcgi
        start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDFILE
        RETVAL="$?"
        [ "$RETVAL" = 2 ] &amp;&amp; return 2
        # Wait for children to finish too if this is a daemon that forks
        # and if the daemon is only ever run from this initscript.
        # If the above conditions are not satisfied then add some other code
        # that waits for the process to drop all resources that could be
        # needed by services started subsequently.  A last resort is to
        # sleep for some time.
        # commenting out this line; probably won't find processes via --exec
        # start-stop-daemon --stop --quiet --oknodo --retry=0/30/KILL/5 --exec $DAEMON
        [ "$?" = 2 ] &amp;&amp; return 2
        # Many daemons don't delete their pidfiles when they exit.
        rm -f $PIDFILE
        return "$RETVAL"
}

case "$1" in
  start)
        [ "$VERBOSE" != no ] &amp;&amp; log_daemon_msg "Starting $DESC" "$NAME"
        do_start
        case "$?" in
                0|1) [ "$VERBOSE" != no ] &amp;&amp; log_end_msg 0 ;;
                2) [ "$VERBOSE" != no ] &amp;&amp; log_end_msg 1 ;;
        esac
        ;;
  stop)
        [ "$VERBOSE" != no ] &amp;&amp; log_daemon_msg "Stopping $DESC" "$NAME"
        do_stop
        case "$?" in
                0|1) [ "$VERBOSE" != no ] &amp;&amp; log_end_msg 0 ;;
                2) [ "$VERBOSE" != no ] &amp;&amp; log_end_msg 1 ;;
        esac
        ;;
  status)
       # added -p $PIDFILE, can't find process otherwise
       status_of_proc -p $PIDFILE "$DAEMON" "$NAME" &amp;&amp; exit 0 || exit $?
       ;;
  restart|force-reload)
        # removed  "$NAME", was repetitive
        log_daemon_msg "Restarting $DESC"
        do_stop
        case "$?" in
          0|1)
                do_start
                case "$?" in
                        0) log_end_msg 0 ;;
                        1) log_end_msg 1 ;; # Old process is still running
                        *) log_end_msg 1 ;; # Failed to start
                esac
                ;;
          *)
                # Failed to stop
                log_end_msg 1
                ;;
        esac
        ;;
  *)
        echo "Usage: $SCRIPTNAME {start|stop|status|restart|force-reload}" >&amp;2
        exit 3
        ;;
esac

:
</pre>
<p><br />
chmod +x /etc/init.d/spawn-fcgi-php<br />
update-rc.d spawn-fcgi-php defaults<br />
cd ../sites-enabled<br />
ln -s ../sites-available/wktk-blog .<br />
ln -s ../sites-available/wktk-blog-proxy .<br />
/etc/init.d/spawn-fcgi-php start<br />
/etc/init.d/nginx start</p>
