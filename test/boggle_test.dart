import 'dart:math';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';
import 'package:dart_boggle/trie.dart';
import 'package:dart_boggle/boggle.dart';

testTrie() {
  test("Single word", () {
    var trie = new TrieNode();
    trie.buildTrie(['cat', 'cat']);
    var c = trie.child('c');
    var a = c.child('a');
    var t = a.child('t');

    expect(trie.children.length, equals(1));

    expect(c.children.length, equals(1));
    expect(c.terminal, isFalse);

    expect(a.children.length, equals(1));
    expect(a.terminal, isFalse);

    expect(t.children.length, equals(0));
    expect(t.terminal, isTrue);
  });

  test("Two different words, contains", () {
    var trie = new TrieNode();
    trie.buildTrie(['one', 'two']);
    expect(trie.children.length, equals(2));
    expect(trie.contains('one'), isTrue);
    expect(trie.contains('two'), isTrue);
    expect(trie.contains('ones'), isFalse);
    expect(trie.contains('on'), isFalse);
    expect(trie.contains('tree'), isFalse);
    expect(trie.contains('four'), isFalse);
  });

  test("Common prefix", () {
    var trie = new TrieNode();
    trie.buildTrie(['can', 'car', 'carat', 'cart', 'cat']);
    expect(trie.contains('can'), isTrue);
    expect(trie.contains('car'), isTrue);
    expect(trie.contains('cat'), isTrue);
    expect(trie.contains('carat'), isTrue);
    expect(trie.contains('cart'), isTrue);
    expect(trie.contains('cara'), isFalse);

    expect(trie.children.length, equals(1));

    var c = trie.child('c');
    expect(c.children.length, equals(1));

    var a = c.child('a');
    expect(a.children.length, equals(3));
  });
}

testGetMatchingWords(die, w, h, match, notmatch) {
  var dict = []
    ..addAll(match)
    ..addAll(notmatch)
    ..sort();
  var trie = new TrieNode();
  trie.buildTrie(dict);

  var boggle = new Boggle(w, h, die);

  test("${w}x${h}[${dict.length}] - getMatchingWords", () {
    var mw = boggle.getMatchingWords(trie);
    expect(mw, unorderedEquals(match));
  });
}

testBoggle() {
  test("3x2 - Neighbors", () {
    var boggle = new Boggle(3, 2, 'AAAAAA');

    expect(boggle.faces[0].neighbors,
        orderedEquals([null, null, 1, 4, 3, null, null, null]));
    expect(boggle.faces[4].neighbors,
        orderedEquals([1, 2, 5, null, null, null, 3, 0]));
    expect(boggle.faces[2].neighbors,
        orderedEquals([null, null, null, null, 5, 4, 1, null]));
    expect(boggle.faces.length, equals(6));
  });
  
  testGetMatchingWords('a', 1, 1, ['a'], []);
  testGetMatchingWords('at', 1, 2, ['at'], []);
  testGetMatchingWords('cat', 1, 3, ['cat'], []);
  testGetMatchingWords('cat', 3, 1, ['cat'], ['rat', 'act', 'caca']);
  testGetMatchingWords('car' + 'nta', 3, 2, [
    'can',
    'car',
    'carat',
    'cart',
    'cat',
    'ant',
    'rant'
  ], ['pony', 'cars', 'nan', 'narc', 'dart', 'caca']);

  test("Word path - single", () {
    var boggle = new Boggle(3, 2, 'carnta');
    var paths = boggle.getWordPaths('carat');
    expect(paths.length, equals(1));
    expect(paths[0], orderedEquals([0, 1, 2, 5, 4]));
  });

  test("Word path - multiple", () {
    var boggle = new Boggle(3, 2, 'carnta');
    var paths = boggle.getWordPaths('carat');
    expect(paths.length, equals(1));
    expect(paths[0], orderedEquals([0, 1, 2, 5, 4]));
  });

  test("Score", () {
    var boggle = new Boggle(3, 2, 'carnta');
    var words = ['can', 'car', 'carat', 'caratn', 'cart', 'dart'];
    var trie = new TrieNode();
    trie.buildTrie(words);
    int score = boggle.getTotalScore(trie);
    expect(score, equals(6));
  });
}

void main() {
  useHtmlEnhancedConfiguration();

  group('Trie', () {
    testTrie();
  });

  group('Boggle', () {
    testBoggle();
  });
}
