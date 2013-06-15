---
layout: post
title: How to install NumPy, SciPy and Matplotlib with HomeBrew
lang: ja
tags : [python, numpy, scipy]
---
1. gfortran is required.
2. umfpack is in suite-sparse package in homebrew.
3. suite-sparse and gfortran formulas are moved to sub repository named science.
4. scipy depends on numpy, but pip doesn't solve it.

So, you can install NumPy, SciPy and Matplotlib with HomeBrew like below.

<pre class="prettyprint linenums lang-bash">
> brew tap homebrew/science
> brew install gfortran umfpack
> pip install numpy matplotlib
> pip install scipy
</pre>
