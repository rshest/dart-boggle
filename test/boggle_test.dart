import 'dart:math';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';
import 'package:dart_boggle/boggle.dart';
import 'package:dart_boggle/grinder.dart';

testUtil() {
  test("Pick random weighted", () {
    var rnd = new Random(123);
    expect(pickRandomW(rnd, [1000000, 1, 1, 1, 1, 1], null), equals(0));
    expect(pickRandomW(rnd, [1, 1, 1, 1, 1000000, 1], null), equals(4));
    expect(pickRandomW(rnd, [0, 0, 0, 0, 0, 1], null), equals(5));
    expect(pickRandomW(rnd, [0, 1, 0, 0, 0, 0], null), equals(1));
  });
}

testTrie() {
  test("Single word", () {
    var trie = new Trie(['cat', 'cat']);
    var c = trie.root.child('c');
    var a = c.child('a');
    var t = a.child('t');
    
    expect(trie.root.children.length, equals(1));
    
    expect(c.children.length, equals(1));
    expect(c.terminal, isFalse);
    
    expect(a.children.length, equals(1));
    expect(a.terminal, isFalse);

    expect(t.children.length, equals(0));
    expect(t.terminal, isTrue);
  });

  test("Two different words, contains", () {
    var trie = new Trie(['one', 'two']);
    
    expect(trie.root.children.length, equals(2));
    expect(trie.contains('one'), isTrue);
    expect(trie.contains('two'), isTrue);
    expect(trie.contains('ones'), isFalse);
    expect(trie.contains('on'), isFalse);
    expect(trie.contains('tree'), isFalse);
    expect(trie.contains('four'), isFalse);
  });

  
  test("Common prefix", () {
    var trie = new Trie(['can', 'car', 'carat', 'cart', 'cat']);
    expect(trie.contains('can'), isTrue);
    expect(trie.contains('car'), isTrue);
    expect(trie.contains('cat'), isTrue);
    expect(trie.contains('carat'), isTrue);
    expect(trie.contains('cart'), isTrue);
    expect(trie.contains('cara'), isFalse);

    expect(trie.root.children.length, equals(1));

    var c = trie.root.child('c');
    expect(c.children.length, equals(1));

    var a = c.child('a');
    expect(a.children.length, equals(3));
  });
  
  test("Common suffix", () {
    var trie = new Trie(["cat", "fat", "mat"]);
    expect(trie.root.children.length, equals(3));
    expect(trie.root.terminal, isFalse);
    
    var c = trie.root.child('c');
    var f = trie.root.child('f');
    var m = trie.root.child('m');
        
    expect(c.children.length, equals(1));
    expect(f.children.length, equals(1));
    expect(m.children.length, equals(1));

    expect(c.terminal, isFalse);
    expect(f.terminal, isFalse);
    expect(m.terminal, isFalse);

    var ca = c.child('a');
    var fa = f.child('a');
    var ma = m.child('a');
    
    expect(ca.children.length, equals(1));
    expect(fa.children.length, equals(1));
    expect(ma.children.length, equals(1));

    expect(identical(ca, fa), isTrue, reason:'Nodes should be collapsed');
    expect(identical(ma, fa), isTrue, reason:'Nodes should be collapsed');

    expect(ma.terminal, isFalse);
    
    var t = f.child('t');
    expect(t.terminal, isTrue);
    expect(t.children.length, equals(0));
  });
  
}

testGetMatchingWords(die, w, h, match, notmatch) {
  var dict = []..addAll(match)..addAll(notmatch)..sort();
  var trie = new Trie(dict);
  
  var boggle = new Boggle(die, w, h);
  
  test("${w}x${h}[${dict.length}] - getMatchingWords", () {
    var mw = boggle.getMatchingWords(trie);
    expect(mw, unorderedEquals(match));
  });
}

testBoggle() {
  test("3x2 - Neighbors", () {
    var boggle = new Boggle('AAAAAA', 3, 2);
    
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
  testGetMatchingWords('car' + 
                       'nta',
                       3, 2,
                       ['can', 'car', 'carat', 'cart', 'cat', 
                        'ant', 'rant'],
                       ['pony', 'cars', 'nan', 'nrc', 'dart', 'caca']);

  test("Word path - single", () {
    var boggle = new Boggle('carnta', 3, 2);
    var paths = boggle.getWordPaths('carat');
    expect(paths.length, equals(1));        
    expect(paths[0], orderedEquals([0, 1, 2, 5, 4]));    
  });

  test("Word path - multiple", () {
    var boggle = new Boggle('carnta', 3, 2);
    var paths = boggle.getWordPaths('carat');
    expect(paths.length, equals(1));        
    expect(paths[0], orderedEquals([0, 1, 2, 5, 4]));    
  });

  test("Score", () {
    var boggle = new Boggle('carnta', 3, 2);
    var trie = new Trie(['can', 'car', 'carat', 'caratn', 'cart', 'dart']);
    int score = boggle.getTotalScore(trie);    
    expect(score, equals(6));    
  });
  
  test("Init random", () {
    String dict = "catz";
    var trie = new Trie(Trie.parseDictionary(dict));
    var dice = Boggle.parseDice("cccccc\naaaaaa\nzzzzzz\ntttttt");
    Boggle board = new Boggle(null, 2, 2);
    Random random = new Random();
    board.initRandom(trie, dice, 4, random);    
    expect(board.letters, equals("CAZT"));  
  });
  
  test("fitDice", () {
    /*
     
   List<int> fitDice(List<Die> dice) {
    if (N != dice.length) return null;
    var res = new List<int>(N);
    
    var mapping = new Map<int, Set<int>>();
    for (int i = 0; i < dice.length; i++) {
      Die die = dice[i];
      for (var d in die.faces) {
        if (!mapping.containsKey(d)) {
          mapping[d] = new Set<int>();
        }
        mapping[d].add(i);
      }
    }
    
    for (var f in faces) {
      print("${f.char}:${mapping[f.code]}");
    }
    
    return res;
  }
     */
    
    //var letters = 'oinetntrcsseaiomndlviocer';
    var letters = 'oclpxniaedstrnseiectrvder';
    var diceStr = '''
aaafrs
aaeeee
aafirs
adennn
aeeeem
aeegmu
aegmnn
afirsy
bjkqxz
ccenst
ceiilt
ceilpt
ceipst
ddhnot
dhhlor
dhlnor
dhlnor
eiiitt
emottt
ensssu
fiprsy
gorrvw
iprrry
nootuw
ooottu''';
    var dice = Boggle.parseDice(diceStr);
    var boggle = new Boggle(letters, 5, 5);
    var res = boggle.fitDice(dice);
    var di = [24, 10, 16, 13, 9, 7, 8, 1, 19, 14, 20, 12, 23, 4, 3, 2, 18, 6, 11, 25, 17, 22, 15, 5, 21];
  });
}

testGrinder() {
  String seed = 'AAAA';
  String dict = "catz";
  var trie = new Trie(Trie.parseDictionary(dict));
  var dice = Boggle.parseDice("cccccc\naaaaaa\ntttttt\nzzzzzz");
  var grinder = new Grinder(dice, trie, 2, 2);
  Boggle board = grinder.grind(seed, 1);
  test("SmallGrind", () {
    expect(board.getTotalScore(trie), equals(1));
  });
}

void main() {
  useHtmlEnhancedConfiguration();
 
  group('Util', () {
    testUtil();
  });
  
  group('Trie', () {
    testTrie();
  });

  group('Boggle', () {
    testBoggle();
  });
  
  group('Grinder', () {
    testGrinder();
  });
}