[![Current PyPI packages](https://badge.fury.io/py/mecab-ko.svg)](https://pypi.org/project/mecab-ko/)
![Test Status](https://github.com/NoUnique/pymecab-ko/workflows/test-manylinux/badge.svg)
[![PyPI - Downloads](https://img.shields.io/pypi/dm/mecab-ko)](https://pypi.org/project/mecab-ko/)
![Supported Platforms](https://img.shields.io/badge/platforms-linux%20macosx%20windows-blue)

# pymecab-ko

This is a Python wrapper for the [MeCab-ko] morphological analyzer for Korean text.
It works with Python 3.6 and greater. 

There are several implementations of python binding or wrapper for MeCab-ko, but they are generally not well maintained.  
I made it to stand on the shoulders of giants(well-maintained open-source projects like [MeCab], [mecab-ko] and [mecab-python3]) with minimum modifications.  
I initially named it `mecab-ko-python3` because the package name referenced for development was [mecab-python3],  
it may seem a little arrogant, but to reduce confusion in the PyPI, the name was changed to 'mecab-ko'.  
(The repository is named 'pymecab-ko' to distinguish it from original [mecab-ko])  

**Note:** If using MacOS Big Sur, you'll need to upgrade pip to version 20.3 or
higher to use wheels due to a pip issue.

**issue를 영어로 작성할 필요는 없습니다.**

[MeCab]: https://taku910.github.io/mecab
[mecab-ko]: https://bitbucket.org/eunjeon/mecab-ko
[mecab-python3]: https://github.com/SamuraiT/mecab-python3

Note that Windows wheels require a [Microsoft Visual C++
Redistributable][msvc], so be sure to install that.

[msvc]: https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads

# Basic usage

```py
>>> import mecab_ko as MeCab
>>> tagger = MeCab.Tagger("-Owakati")
>>> tagger.parse("아버지가방에들어가신다").split()
['아버지', '가', '방', '에', '들어가', '신다']

>>> tagger = MeCab.Tagger()
>>> print(tagger.parse("아버지가방에들어가신다"))
아버지  NNG,*,F,아버지,*,*,*,*
가      JKS,*,F,가,*,*,*,*
방      NNG,*,T,방,*,*,*,*
에      JKB,*,F,에,*,*,*,*
들어가  VV,*,F,들어가,*,*,*,*
신다    EP+EC,*,F,신다,Inflect,EP,EC,시/EP/*+ㄴ다/EC/*
EOS
```

The API for `pymecab-ko` closely follows the API for MeCab itself,
even when this makes it not very “Pythonic.”  Please consult the [official MeCab
documentation][mecab-docs] for more information.

[mecab-docs]: https://taku910.github.io/mecab/

# Installation

Binary wheels are available for MacOS X, Linux, and Windows (64bit) are
installed by default when you use `pip`:

```sh
pip install mecab-ko
```

These wheels include a copy of the MeCab-ko library and a dictionary.
There is a unique dictionary available for MeCab-ko. `mecab-ko-dic` is automatically installed when installing pymacab-ko.

To build from source using pip,

```sh
pip install --no-binary :all: mecab-ko
```

## Dictionaries

In order to use MeCab-ko, you must install a dictionary. There are 2 dictionaries available for MeCab-ko.  
These packages, which include slight modifications for ease of use, are recommended:

- [mecab-ko-dic](https://github.com/LuminosoInsight/mecab-ko-dic): The pre-built [mecab-ko-dic](https://bitbucket.org/eunjeon/mecab-ko-dic) 2.1.1-20180720 based on [ipadic-py](https://github.com/polm/ipadic-py). It will be installed along with pymecab-ko.
- [openkorpos-dic](https://github.com/NoUnique/openkorpos-dic-py): [a dictionary](https://github.com/openkorpos/model-mecab) trained with [OpenKorPOS](https://github.com/openkorpos/openkorpos)(Free and open alternative to the Sejong corpus)
# Common Issues

If you get a `RuntimeError` when you try to run MeCab, here are some things to check:

## Windows Redistributable

You have to install [this][msvc] to use this package on Windows.

## Specifying a mecabrc

If you get this error:

    error message: [ifs] no such file or directory: /usr/local/etc/mecabrc

You need to specify a `mecabrc` file. It's OK to specify an empty file, it just
has to exist. You can specify a `mecabrc` with `-r`. This may be necessary on
Debian or Ubuntu, where the `mecabrc` is in `/etc/mecabrc`.

You can specify an empty `mecabrc` like this:

    tagger = MeCab.Tagger('-r/dev/null -d/home/hoge/mydic')

## Using Unsupported Output Modes like `-Ochasen`

Chasen output is not a built-in feature of MeCab, you must specify it in your
`dicrc` or `mecabrc`. Notably, mecab-ko-dic does not include Chasen output format.
Please see [the MeCab documentation](https://taku910.github.io/mecab/#format).

# Alternatives

- [python-mecab-ko](https://github.com/jonghwanhyeon/python-mecab-ko) is a Python binding for MeCab-ko
- [mecab-python-msvc](https://github.com/Pusnow/mecab-python-msvc) is a mecab-python for mecab-ko-msvc 
- [KoNLPy](https://konlpy.org/en/latest/) is a library for Korean NLP that includes a MeCab wrapper

# Licensing

Like MeCab and mecab-python3, `pymecab-ko` is copyrighted free software by
Taku Kudo <taku@chasen.org> and Nippon Telegraph and Telephone Corporation,
and is distributed under a 3-clause BSD license (see the file `BSD`).
Alternatively, it may be redistributed under the terms of the
GNU General Public License, version 2 (see the file `GPL`) or the
GNU Lesser General Public License, version 2.1 (see the file `LGPL`).
