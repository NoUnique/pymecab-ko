[![Current PyPI packages](https://badge.fury.io/py/mecab-ko-python3.svg)](https://pypi.org/project/mecab-ko-python3/)
![Test Status](https://github.com/NoUnique/mecab-python3/workflows/test-manylinux/badge.svg)
[![PyPI - Downloads](https://img.shields.io/pypi/dm/mecab-ko-python3)](https://pypi.org/project/mecab-ko-python3/)
![Supported Platforms](https://img.shields.io/badge/platforms-linux%20macosx%20windows-blue)

# mecab-ko-python3

This is a Python wrapper for the [MeCab-ko][] morphological analyzer for Korean text.
It works with Python 3.6 and greater. 

Even though there are several implementations of python binding or wrapper for MeCab-ko, it is hard to maintain them.
I made it to stand on the shoulders of giants(Well-maintained open-source projects) with slight modifications.

**Note:** If using MacOS Big Sur, you'll need to upgrade pip to version 20.3 or
higher to use wheels due to a pip issue.

**issue를 영어로 작성할 필요는 없습니다.**

[MeCab]: https://taku910.github.io/mecab/
[MeCab-ko]: https://taku910.github.io/mecab/
[mecab-python3]: https://github.com/SamuraiT/mecab-python3

Note that Windows wheels require a [Microsoft Visual C++
Redistributable][msvc], so be sure to install that.

[msvc]: https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads

# Basic usage

```py
>>> import mecab_ko as MeCab
>>> tagger = MeCab.Tagger()
>>> tagger.parse("아버지가방에들어가신다").split()[:-1:2]
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

The API for `mecab-ko-python3` closely follows the API for MeCab itself,
even when this makes it not very “Pythonic.”  Please consult the [official MeCab
documentation][mecab-docs] for more information.

[mecab-docs]: https://taku910.github.io/mecab/

# Installation

Binary wheels are available for MacOS X, Linux, and Windows (64bit) are
installed by default when you use `pip`:

```sh
pip install mecab-ko-python3
```

These wheels include an internal (statically linked) copy of the MeCab library,
but not dictionary. In order to use MeCab you'll need to install a dictionary.
`mecab-ko-dic` is a good one to start with:

```sh
pip install mecab-ko-dic
```

To build from source using pip,

```sh
pip install --no-binary :all: mecab-ko-python3
```

## Dictionaries

There is a unique dictionary available for MeCab-ko. These UniDic packages, which include slight modifications for ease of use, are recommended:

- [mecab-ko-dic](https://github.com/LuminosoInsight/mecab-ko-dic): The pre-built mecab-ko-dic 2.1.1-20180720 based on [ipadic-py](https://github.com/polm/ipadic-py).
- [mecab-ko-dic](https://bitbucket.org/eunjeon/mecab-ko-dic): The original source-code of mecab-ko-dic to build dictionary for mecab-ko.

# Common Issues

If you get a `RuntimeError` when you try to run MeCab, here are some things to check:

## Windows Redistributable

You have to install [this][msvc] to use this package on Windows.

## Installing a Dictionary

Run `pip install mecab-ko-dic` and confirm that works. If that fixes your
problem, you either don't have a dictionary installed, or you need to specify
your dictionary path like this:

    tagger = MeCab.Tagger('-r /dev/null -d /usr/local/lib/mecab/dic/mydic')

Note: on Windows, use `nul` instead of `/dev/null`. Alternately, if you have a
`mecabrc` you can use the path after `-r`.

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
`dicrc` or `mecabrc`. Notably, Unidic does not include Chasen output format.
Please see [the MeCab documentation](https://taku910.github.io/mecab/#format).

# Alternatives

- [python-mecab-ko](https://github.com/jonghwanhyeon/python-mecab-ko) is a Python binding for MeCab-ko
- [mecab-python-msvc](https://github.com/Pusnow/mecab-python-msvc) is a mecab-python for mecab-ko-msvc 
- [KoNLPy](https://konlpy.org/en/latest/) is a library for Korean NLP that includes a MeCab wrapper

# Licensing

Like MeCab and mecab-python3, `mecab-ko-python3` is copyrighted free software by
Taku Kudo <taku@chasen.org> and Nippon Telegraph and Telephone Corporation,
and is distributed under a 3-clause BSD license (see the file `BSD`).
Alternatively, it may be redistributed under the terms of the
GNU General Public License, version 2 (see the file `GPL`) or the
GNU Lesser General Public License, version 2.1 (see the file `LGPL`).
