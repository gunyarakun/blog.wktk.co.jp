---
date: 2024-03-15
lang: ja
layout: post
tags: [ml,aws,pytorch]
title: AWSのaarch64/arm64でNVIDIA T4G搭載インスタンスであるG5gインスタンスのDocker内で任意のPyTorchをCUDAで動かす with Ubuntu 22.04
---
AWSにはG5gという、Gravitonを用いたaarch64でGPU(NVIDIA T4G)が使えるインスタンスがある。ちょっとした機械学習アプリケーションをデプロイするのに使ってみたい。8xlargeまではT4Gが1個でGPUメモリは16GB、16xlargeからはT4Gが2個でGPUメモリはトータル32GB。

AWS Graviton2 プロセッサと NVIDIA T4G Tensor Core GPU を搭載した Amazon EC2 G5g インスタンス
https://aws.amazon.com/jp/blogs/news/new-amazon-ec2-g5g-instances-powered-by-aws-graviton2-processors-and-nvidia-t4g-tensor-core-gpus/

AMIも準備されたものがなく、prebuiltなimageがaarch64だとなかったりしてハマりがち。

バージョンは以下のとおり。

```
Ubuntu 22.04
PyTorch 2.2.1
torchaudio
CUDA 12.1
```

そろそろUbuntu 24.04も出ると思うが、基本は変わらないはず。

## ホスト側

以下の手順で、AWSのデフォルトubuntuユーザでDocker内でNVIDIA T4Gを見えるようにできた。

```
# Dockerのインストール
# official GPG keyを登録
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# aptのsourceにDocker公式を追加
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Dockerをインストール
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# ubuntu userをDocker groupに追加
sudo groupadd docker
sudo usermod -aG docker ubuntu

# Docker自動起動
sudo systemctl enable docker.service
sudo systemctl enable containerd.service


# NVIDIAのデバイスが見えているか確認
lspci | grep -i nvidia

# デフォルトドライバであるnouveauがロードされていないことを確認
lsmod | grep -i nouveau

# https://developer.nvidia.com/cuda-downloads
# で生成したCUDA公式レポジトリからkeyringを取得し、cuda-toolkitとcuda-driversをインストール
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/sbsa/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get install -y cuda-toolkit-12-4
sudo apt-get install -y cuda-drivers

# いったんreboot
sudo reboot
```

Rebootから復帰後。

```
# nvidia-smiでGPU見えることを確認
nvidia-smi

# libnvidia-containerのインストール
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Docker内でnvidia-smiがうまく動くことを確認
sudo docker run --rm --runtime=nvidia --gpus all nvidia/cuda:11.6.2-base-ubuntu20.04 nvidia-smi
```

## Docker上でPyTorch, torchaudioのwheelをビルドする

上記の設定を `g5g.8xlarge` で行い、ビルドする。より非力なマシンだとビルド自身がスタックするかもしれない。ストレージは128GB用意したが、


PyTorch公式のPyTorch Buildから、Stableのバージョンと、Compute PlatformのCUDAのバージョンをメモする。今回は、Stableが2.2.1、CUDAが12.1だった。
https://pytorch.org/get-started/locally/

以下のURLから、cuDNNまでビルドされたaarch64でUbuntu環境のDocker base imageが閲覧できる。上記のPyTorchサイトで調べたCUDAのバージョンのimageのうち、任意のUbuntuバージョンで、aarch64でビルドされたイメージがあるもので `devel` のものを選ぶ。

今回は `nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04` を選んだ。これを使ってPyTorch, torchaudioをビルドしていって、wheelを作る。

まずはdevelをbaseにした、build用のDockerfileを作成する。

以下のDockerfileで、コンテナ内の `/dist` にPyTorchとtorchaudioの2つのwhlファイルが置かれる。あとはmountしたりdocker cpしたりしてwhlファイル群をホストに持ってきて保存するだけ！

……のはずなのだが、以下のDockerfileはPyTorchのconfigureでエラーが出ちゃう。その直前までのDockerコンテナを作ってbash実行してコマンド実行すればできるので、とりあえずそれでなんとかしている。誰か深堀りして欲しい。

```
FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04 as python

# Install Python with python-build from pyenv
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
  git \
  curl \
  build-essential \
  libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev \
  cmake ninja-build \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install Python 3.11.8 with python-build (a plugin of pyenv)
RUN git clone https://github.com/pyenv/pyenv.git /pyenv
RUN /pyenv/plugins/python-build/bin/python-build 3.11.8 /python
ENV PATH "/python/bin:${PATH}"

# Checkout PyTorch v2.2.1
RUN git clone --recursive --depth 1 --branch v2.2.1 http://github.com/pytorch/pytorch /pytorch
# Install required modules to build
RUN pip install wheel pyyaml numpy typing-extensions
# Build a wheel specifying the version 2.2.1 (You can set any PYTORCH_BUILD_NUMBER)
RUN cd /pytorch && PYTORCH_BUILD_VERSION=2.2.1 PYTORCH_BUILD_NUMBER=1 python setup.py bdist_wheel
# Install PyTorch from a built wheel
RUN pip install dist/torch-2.2.1-cp311-cp311-linux_aarch64.whl

# Checkout torchaudio 2.2.1
RUN git clone --recursive --depth 1 --branch v2.2.1 http://github.com/pytorch/audio /torchaudio
# Build a wheel specifying the version 2.2.1
RUN cd /torchaudio && BUILD_VERSION=2.2.1 python setup.py bdist_wheel

# Copy all the wheels into /dist
RUN mkdir /dist && cp /pytorch/dist/torch-2.2.1-cp311-cp311-linux_aarch64.whl /dist && cp /torchaudio/dist/torchaudio-2.2.1-cp311-cp311-linux_aarch64.whl /dist
```

## Dockerでビルドされたwheelを用いる

実際に利用するG5gインスタンスを立てて、Dockerあたりのインストールを設定する。また、上記ビルドで作ったwheelファイルたちをコピーしてくる。

実際に利用するコンテナのbase imageは、`devel` ではなく `runtime` のイメージでよいのでは、と思って `nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04` を試したら、`libcupti.so` が見つからない、と言われてエラーになった。ファイル見つけて `LD_LIBRARY_PATH` でもしたらいいのかもしれないが、めんどい。

すなおに `nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04` を使い、あとはビルドされたwheelたちを `pip install` したら、無事PyTorch/torchaudio環境が手に入った。

```
import torch
print(torch.cuda.is_available())
```
