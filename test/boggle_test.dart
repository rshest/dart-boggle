import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';
import 'package:dart_boggle/dawg.dart';
import 'package:dart_boggle/boggle.dart';

testDawg() {
  test("Single word", () {
    var dawg = new Dawg(['cat', 'cat']);
    var c = dawg.root.child('c');
    var a = c.child('a');
    var t = a.child('t');
    
    expect(dawg.root.children.length, equals(1));
    
    expect(c.children.length, equals(1));
    expect(c.terminal, isFalse);
    
    expect(a.children.length, equals(1));
    expect(a.terminal, isFalse);

    expect(t.children.length, equals(0));
    expect(t.terminal, isTrue);
  });

  test("Two different words, contains", () {
    var dawg = new Dawg(['one', 'two']);
    
    expect(dawg.root.children.length, equals(2));
    expect(dawg.contains('one'), isTrue);
    expect(dawg.contains('two'), isTrue);
    expect(dawg.contains('ones'), isFalse);
    expect(dawg.contains('on'), isFalse);
    expect(dawg.contains('tree'), isFalse);
    expect(dawg.contains('four'), isFalse);
  });

  
  test("Common prefix", () {
    var dawg = new Dawg(['can', 'car', 'carat', 'cart', 'cat']);
    expect(dawg.contains('can'), isTrue);
    expect(dawg.contains('car'), isTrue);
    expect(dawg.contains('cat'), isTrue);
    expect(dawg.contains('carat'), isTrue);
    expect(dawg.contains('cart'), isTrue);
    expect(dawg.contains('cara'), isFalse);

    expect(dawg.root.children.length, equals(1));

    var c = dawg.root.child('c');
    expect(c.children.length, equals(1));

    var a = c.child('a');
    expect(a.children.length, equals(3));
  });
  
  test("Common suffix", () {
    var dawg = new Dawg(["cat", "fat", "mat"]);
    expect(dawg.root.children.length, equals(3));
    expect(dawg.root.terminal, isFalse);
    
    var c = dawg.root.child('c');
    var f = dawg.root.child('f');
    var m = dawg.root.child('m');
        
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
  var dawg = new Dawg(dict);
  
  var boggle = new Boggle(die, w, h);
  
  test("${w}x${h}[${dict.length}] - getMatchingWords", () {
    var mw = boggle.getMatchingWords(dawg);
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
    var dawg = new Dawg(['can', 'car', 'carat', 'cart', 'caratn', 'dart']);
    int score = boggle.getTotalScore(dawg);    
    expect(score, equals(6));    
  });
}

void main() {
  useHtmlEnhancedConfiguration();
  
  group('Dawg', () {
    testDawg();
  });

  group('Boggle', () {
    testBoggle();
  });
}