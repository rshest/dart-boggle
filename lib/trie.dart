library trie;

class TrieNode {
  bool terminal = false;
  final Map<int, TrieNode> children = new Map();
  
  TrieNode child(String s) => children[s.codeUnitAt(0)];
  
  buildTrie(Iterable<String> words) {
    for (String word in words) {
      insertWord(word, 0);
    }
  }

  insertWord(String word, [int startChar = 0]) {
    if (startChar == word.length) {
      terminal = true;
      return;
    }
    int key = word.codeUnitAt(startChar);
    var child = children[key];
    if (child == null) {
      child = new TrieNode();
      children[key] = child;
    }
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