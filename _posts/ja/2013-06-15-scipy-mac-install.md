---
layout: post
title: How to install NumPy, SciPy and Matplotlib with HomeBrew
lang: ja
tags : [python, numpy, scipy]
---
1. gfortran and swig is required.
2. umfpack required in numpy is in suite-sparse package in homebrew.
3. suite-sparse and gfortran formulas are moved to sub repository named science.
4. scipy depends on numpy, but pip doesn't solve it.
5. The file 'npymath.ini' is required by SciPy, but current numpy formula doesn't leave the file. So we install numpy of develop version from github directly.
5. matplotlib requires freetype2

So, you can install NumPy, SciPy and Matplotlib with HomeBrew like below.

<pre class="prettyprint linenums lang-bash">
> brew tap homebrew/science
> brew install gfortran suite-sparse swig freetype
> pip install -e git+https://github.com/numpy/numpy#egg=numpy-dev
> pip install scipy matplotlib
</pre>

Note: don't delete 'src' directory created by pip.

You can install SciPy of develop version. It is not required.
