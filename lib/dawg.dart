library dawg;
import 'dart:collection';

class DawgNode {
  bool terminal = false;
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
    child.insertWord(word, startChar + 1);
  }
  
  bool contains(String word, [int startChar = 0]) {
    if (startChar == word.length) {
      return terminal;
    }
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
    for (String word in words) {
      root.insertWord(word);
    }
  }
  
}