---
layout: post
title: GIFアニメーションでフレーム差分の最適化がなされている場合に画像を1コマずつ分解して取り出す
lang: ja
tags : [image]
---
ImageMagickを使って、以下のように出来る。GraphicsMagickでもできるはずだが、1.3.18ではうまくいかなかった。+adjoinをつければGraphicsMagickでもいけるのかもしれない。

<pre class="prettyprint linenums lang-bash">
> convert -coalesce input.gif output%02d.gif
</pre>
