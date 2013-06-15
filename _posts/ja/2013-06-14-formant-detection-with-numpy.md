---
layout: post
title: Python(NumPy, SciPy)でフォルマント分析を行う
lang: ja
tags : [python, numpy, scipy]
---
RubyMotionブームが俺の中で巻き起こり、社内で布教活動をしていました。「やっぱり自分でアプリを作ってリリースまで持っていかないと、きちんと評価できないよね」ということで、前から作りたかった音声解析アプリを作り始めました。

そのために信号処理のアルゴリズムを勉強しましたが、む、難しい。

さて、RubyMotionはvendorディレクトリに適当に.mと.hを突っ込んでおいて、Rakefileで指定しておけばObjective-Cのコードをコンパイルしてくれます。

信号処理はなるべく高速化したいので、Objective-C(というか、C言語)で書きたいです。RubyMotionでは、そういった用途にも比較的楽に対応できる感じになっているわけです。
## 信号処理アルゴリズムを俺がC言語で実装する必要性

C言語で複雑な信号処理のアルゴリズムの実装は難しいです。

インターネットに落ちている実装snippetを使うという選択肢もあるのかもしれませんが、ライセンスが不明なことが多いです。さらに、少ない領域であっても中でmalloc()しまくったり、ANSI Cですらなかったりと、あんまり素敵じゃないコードが多いです。よっぽどサイズが大きくない限り、普通にスタックに作業領域取っちゃえばいいですし、計算結果を格納する領域はcaller側が管理したほうがいい。

何かしらの既存のライブラリを使うという選択肢もありますが、基本リッチすぎてフットプリント食っちゃうし、RubyMotionのvendorディレクトリにファイル一個どーん！的な感じでやりたいですよね。

というわけで、なんとか頑張ってC言語で依存ライブラリなく信号処理アルゴリズムを書こうと決断ポトフしたわけです。合理性には欠けているけど。

しかし、何のリファレンスもなく実装するとバグるし、バグっていることにすら気づかない状態に陥ります。なんらかのリファレンス実装が必要です。

## リファレンス実装を探して三千里

僕がやりたいのは、音声からフォルマントを抽出するという処理です。インターネットを検索したところ、<a href="http://www.mathworks.co.jp/jp/help/signal/ug/formant-estimation-with-lpc-coefficients.html">リファレンス実装ありました！MATLABですが。</a>

フォルマントを求めるためには、線形予測分析というものを行いLPCを求める必要があります。LPCは係数群なのですが、その係数群をもつ多項式の根を求めればいいらしい。ほうほう。

MATLABのコードがあるので、GNU Octaveで試してみてもいいかなー、と思いましたが、正直MATLABのコードに詳しくない。

情報を求めて、さらにインターネットの海を漂ってみました。<a href="http://link.springer.com/article/10.1007%2Fs11075-012-9579-5">ブログ「人工知能に関する断創録」にある、線形予測分析（LPC）のエントリを発見。</a>テストコードがPythonで書かれている。読めるぞ書けるぞ。

当該エントリには、LPCスペクトル崩落をもとに母音のフォルマントを抽出したい、という発言がありますが、その後追いエントリは存在しないようです。俺それ欲しいんす。じゃあ、書くか。

## 俺のためのPythonリファレンス実装

というわけで、当該エントリのSciPy, NumPyを用いたPythonコードを拡張して、上記のMATLABコードと同様の処理を実装してみました。

当該ブログのlevinson_durbin.pyが置いてある必要あり。あと、ほとんどのコードは上記ブログ由来のものです。

<pre class="prettyprint linenums lang-python">
# coding:utf-8
import wave
import numpy as np
import scipy.io.wavfile
import scipy.signal
from levinson_durbin import autocorr, LevinsonDurbin

"""LPCスペクトル包絡を求める"""

def wavread(filename):
    wf = wave.open(filename, "r")
    fs = wf.getframerate()
    x = wf.readframes(wf.getnframes())
    x = np.frombuffer(x, dtype="int16") / 32768.0  # (-1, 1)に正規化
    wf.close()
    return x, float(fs)

def preEmphasis(signal, p):
    """プリエンファシスフィルタ"""
    # 係数 (1.0, -p) のFIRフィルタを作成
    return scipy.signal.lfilter([1.0, -p], 1, signal)

if __name__ == "__main__":
    # 音声をロード
    wav, fs = wavread("a.wav")
    t = np.arange(0.0, len(wav) / fs, 1/fs)

    # 音声波形の中心部分を切り出す
    center = len(wav) / 2  # 中心のサンプル番号
    cuttime = 0.04         # 切り出す長さ [s]
    s = wav[center - cuttime/2*fs : center + cuttime/2*fs]

    # プリエンファシスフィルタをかける
    p = 0.97         # プリエンファシス係数
    s = preEmphasis(s, p)

    # ハミング窓をかける
    hammingWindow = np.hamming(len(s))
    s = s * hammingWindow

    # LPC係数を求める
    lpcOrder = 12
    r = autocorr(s, lpcOrder + 1)

    a, e  = LevinsonDurbin(r, lpcOrder)

    # フォルマント検出( by Tasuku SUENAGA a.k.a. gunyarakun )

    # 根を求めて三千里
    rts = np.roots(a)
    # 共役解のうち、虚部が負のものは取り除く
    rts = np.array(filter(lambda x: np.imag(x) >= 0, rts))

    # 根から角度を計算
    angz = np.arctan2(np.imag(rts), np.real(rts))
    # 角度の低い順にソート
    sorted_index = angz.argsort()
    # 角度からフォルマント周波数を計算
    freqs = angz.take(sorted_index) * (fs / (2 * np.pi))
    # 角度からフォルマントの帯域幅も計算
    bw = -1 / 2 * (fs / (2 * np.pi)) * np.log(np.abs(rts.take(sorted_index)))

    for i in range(len(freqs)):
      # フォルマントの周波数は90Hz超えで、帯域幅は400Hz未満
      if freqs[i] > 90 and bw[i] < 400:
        print "formant kita-: %d" % freqs[i]
</pre>

できたー。

## C言語の実装はできたのか

多項式の根を求めるために、コンパニオン行列の固有値を求める必要があります。Numerical Recipes in CにはLaguerre法というものが紹介されていますが、固有値を求めるのが一般的な様子。

そこがまだ実装できていなくて、C言語版はまだ未完成人。

<a href="http://link.springer.com/article/10.1007%2Fs11075-012-9579-5">つーか、コンパニオン行列の固有値を求めるアルゴリズムについての論文が今年の2月に出てるし。</a>まだまだホットな分野ということだろうか。
