---
date: 2024-03-19
lang: ja
layout: post
tags: [ssh,quic]
title: quicssh-rsをdebパッケージで入れて自動起動する
---
quicssh-rs、VSCodeでリモート開発するときに安定して便利。

新幹線でもQUICで快適にSSHする
https://qiita.com/tksst/items/68e8f802822913025286

以下の手順でdebファイル作って入れている。debファイルを保存しておいて同様な環境の場合はシュっとインストールしている。

```
# cargo
curl https://sh.rustup.rs -sSf | sh
. "$HOME/.cargo/env"

# cargo-deb
cargo install cargo-deb

# fetch quicssh-rs
git clone https://github.com/oowl/quicssh-rs.git
cd quicssh-rs

# create a deb
cargo deb

# install the deb
sudo dpkg -i ./target/debian/quicssh-rs_0.1.4+autopublish-1_amd64.deb

# Add a service file
sudo cat <<EOT > /etc/systemd/system/quicssh-rs.service
[Unit]
Description=QUIC ssh proxy
After=syslog.target network.target

[Service]
Type=simple
ExecStart=/usr/bin/quicssh-rs server
WorkingDirectory=/tmp
KillMode=process
Restart=always

[Install]
WantedBy=multi-user.target
EOT

# Enable the service
sudo systemctl enable quicssh-rs.service
sudo systemctl start quicssh-rs.service
```

接続元の `.ssh/config` にホスト足しとく。接続元にもquicssh-rsのインストールが必要。

```
Host host-quic
    User tasuku
    ProxyCommand quicssh-rs client quic://192.168.0.1:4433
```
