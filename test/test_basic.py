#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# Minimal test of MeCab functionality.

import contextlib
import sys
import unittest

import mecab_ko as MeCab


# TODO: More test sentences.
SENTENCE = "아버지가방에들어가신다."

SENTENCES = (
    ("아버지가방에들어가신다", "아버지 가 방 에 들어가 신다".split()),
    ("영등포구청역에 있는 맛집 좀 알려주세요.", "영등포구청역 에 있 는 맛집 좀 알려 주 세요 .".split()),
    ("우리나라에는 무릎 치료를 잘하는 정형외과가 없는가!", "우리 나라 에 는 무릎 치료 를 잘 하 는 정형외과 가 없 는가 !".split()),
    ("자연주의 쇼핑몰은 어떤 곳인가?", "자연주의 쇼핑몰 은 어떤 곳 인가 ?".split()),
    ("전체적으로 편안하고 아늑한 공간으로 꾸며져 있었습니다ㅎㅎ "
     "한가지 아쉬웠던 건 조명이 너무 어두워 눈이 침침했던...",
     "전체 적 으로 편안 하 고 아늑 한 공간 으로 꾸며져 있 었 습니다 ㅎ ㅎ "
     "한 가지 아쉬웠 던 건 조명 이 너무 어두워 눈 이 침침 했 던 . .."
     .split())
)

# BUG: If we instantiate a new tagger for each test case, then the
# second and subsequent tagger instantiations will produce garbage.
# I suspect this is a bug somewhere within libmecab itself.
TAGGER = MeCab.Tagger()

# Check if we are using mecab-ko-dic and only test in that case.
USING_KODIC = False
try:
    import mecab_ko_dic  # noqa: F401
    USING_KODIC = True
except ImportError:
    pass


def sub_test(testcase, *args, **kwargs):
    return testcase.subTest(*args, **kwargs)


class TestTagger(unittest.TestCase):
    def setUp(self):
        self.tagger = TAGGER

    def test_metadata(self):
        sys.stdout.write("# Testing MeCab version {}\n".format(MeCab.VERSION))

        d = self.tagger.dictionary_info()
        if not d:
            sys.stdout.write("# No dictionaries found.\n")
            return

        n = 1
        while d:
            sys.stdout.write("# Dictionary #{}:\n"
                             "#    filename: {}\n"
                             "#     version: {}\n"
                             "#     charset: {}\n"
                             "#        type: {}\n"
                             "#        size: {}\n"
                             "#       lsize: {}\n"
                             "#       rsize: {}\n"
                             .format(n, d.filename, d.version, d.charset,
                                     d.type, d.size, d.lsize, d.rsize))
            n += 1
            d = d.next

    # The segmentation of the test sentence could vary depending on
    # the dictionaries available, so we can't test for a specific
    # result.  However, parse() and parseToNode() should always
    # produce a sequence of nodes whose "surface"s do not overlap
    # and which add back up to be the entire sentence.  (This will,
    # for instance, detect a regression of
    # https://github.com/SamuraiT/mecab-python3/issues/19 .)

    # XXX The above is not strictly true - "surface" does not include some
    # kinds of whitespace. If your input is "hello how are you" there will be
    # no white space in the surfaces. It seems the only way to tell if there
    # was a space from the C api is to check if rlength is longer than length
    # for a node, in which case there was a space before it.

    def tokenize(self, sentence):
        parsed = self.tagger.parse(sentence)
        nodes = []
        last = False
        for line in parsed.splitlines():
            if line == "EOS":
                last = True
                continue
            self.assertFalse(last)
            surface, feature = line.strip().split("\t", 1)
            nodes.append((surface, feature))
        self.assertTrue(last)
        return nodes

    def test_parse(self):
        nodes = self.tokenize(SENTENCE)
        self.validateNodes(SENTENCE, nodes)

    def test_parseToNode(self):
        m = self.tagger.parseToNode(SENTENCE)
        nodes = []
        while m:
            nodes.append((m.surface, m.feature))
            m = m.next
        self.validateNodes(SENTENCE, nodes)

    @unittest.skipIf(not USING_KODIC, "Not using mecab-ko-dic")
    def test_tokenization(self):
        for sentence, answer in SENTENCES:
            tokens = [tok[0] for tok in self.tokenize(sentence)]
            
            with self.subTest(sentence=sentence):
                self.assertEqual(tokens, answer)

    def validateNodes(self, sentence, nodes):
        for surface, feature in nodes:
            n = len(surface)
            self.assertTrue(len(sentence) >= n)
            self.assertEqual(surface, sentence[:n])
            sentence = sentence[n:]
        self.assertEqual(sentence, u"")

    def test_parseToLattice(self):
        lattice = MeCab.Lattice()
        lattice.set_sentence(SENTENCE)
        self.tagger.parse(lattice)


if __name__ == "__main__":
    unittest.main()
