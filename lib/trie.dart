library trie;

class TrieNode {
  int pathCount = 0; //  number of words through the node
  int score = 0; //  cached word score (if terminal)
  int scoreContrib = 0; //  total score contribution for the node
  bool visited = false;
  bool terminal = false;

  final Map<int, TrieNode> children = new Map();

  child(String s) => children[s.codeUnitAt(0)];

  insertWord(String word, [int startChar = 0, int wordScore = 0]) {
    if (startChar == word.length) {
      score = wordScore;
      terminal = true;
      scoreContrib += score;
      return score;
    }
    int key = word.codeUnitAt(startChar);
    var child = children[key];
    if (child == null) {
      child = new TrieNode();
      children[key] = child;
    }
    child.pathCount++;
    int branchScore = child.insertWord(word, startChar + 1, wordScore);
    scoreContrib += branchScore;
    return branchScore;
  }

  bool contains(String word, [int startChar = 0]) {
    if (startChar == word.length) return terminal;
    int key = word.codeUnitAt(startChar);
    var child = children[key];
    if (child == null) return false;
    return child.contains(word, startChar + 1);
  }
}

// trie data structure
class Trie {
  TrieNode root;
  get contains => root.contains;

  Trie(Iterable<String> words, [scoreFn = null]) {
    root = new TrieNode();
    String prevWord = "";
    for (String word in words) {
      assert(word.compareTo(prevWord) >= 0);
      root.insertWord(word, 0, scoreFn == null ? 0 : scoreFn(word));
      prevWord = word;
    }
  }

  static List<String> parseDictionary(String dict, [bool skipImpossible = true]) {
    var re = new RegExp("q(?!u)|-|'|/");
    return dict
        .split(' ')
        .where((s) => !skipImpossible || !re.hasMatch(s))
        .map((s) => s.trim().toLowerCase().replaceAll('qu', 'q'))
        .toList()..sort();
  }
}
