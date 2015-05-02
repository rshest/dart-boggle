library dawg;
import 'dart:collection';

class DawgNode {
  bool terminal = false;
  int pathCount = 0;
  final Map<int, DawgNode> children = new Map();
  
  child(String s) => children[s.codeUnitAt(0)];
     
  insertWord(String word, [int startChar = 0]) {
    if (startChar == word.length) {
      terminal = true;
      return;
    }
    int key = word.codeUnitAt(startChar);
    var child = children[key];
    if (child == null) {
      child = new DawgNode();
      children[key] = child;
    } 
    child.pathCount++;
    child.insertWord(word, startChar + 1);
  }
  
  bool contains(String word, [int startChar = 0]) {
    if (startChar == word.length) return terminal;
    int key = word.codeUnitAt(startChar);
    var child = children[key];
    if (child == null) return false;
    return child.contains(word, startChar + 1);
  }
}

class Dawg {
  DawgNode root;
  get contains => root.contains;

  Dawg(Iterable<String> words) {
    root = new DawgNode();
    String prevWord = "";
    for (String word in words) {
      assert(word.compareTo(prevWord) >= 0);
      root.insertWord(word);
      prevWord = word;
    }
  }
  
  static List<String> parseDictionary(String dict) {
    var re = new RegExp("q(?!u)");
    return dict.split(' ')
               .where((s) => !re.hasMatch(s))
               .map((s) => s.trim().toLowerCase().replaceAll('qu', 'q'))
               .toList()..sort();   
  }
}