library boggle;

import 'dart:math';
import 'trie.dart';

class BoggleFace {
  static const NUM_NEIGHBORS = 8;
  final neighbors = new List<int>(NUM_NEIGHBORS); // clockwise, from top
  int code; // character code
  bool visited = false;

  get char => new String.fromCharCode(code);
  set char(String s) => code = s.codeUnitAt(0);
}

class Boggle {
  final int width, height, N;
  final List<BoggleFace> faces;
  int score;

  static const SCORE_LOOKUP = const [0, 0, 0, 0, 1, 2, 3, 5, 11];
  static const OFFX = const [0, 1, 1, 1, 0, -1, -1, -1];
  static const OFFY = const [-1, -1, 0, 1, 1, 1, 0, -1];
  static offsets(int w) => [-w, -w + 1, 1, w + 1, w, w - 1, -1, -w - 1];
  
  static final Q_CODE = "q".codeUnitAt(0);

  get letterList => faces.map((f) => f.char.toUpperCase());
  get letters => letterList.join('');

  set letterList(List<int> lst) {
    for (int i = 0; i < N; i++) faces[i].code = lst[i];
  }

  set letters(String s) {
    assert(s.length == N);
    for (int i = 0; i < N; i++) faces[i].char = s[i];
  }

  //  word scoring function
  static int scoreLen(int n) => SCORE_LOOKUP[min(8, n)];
  static int scoreWord(String word) {
    int len = word.length;
    int effectiveLen = len;
    for (var i = 0; i < len; i++) {
      if (word.codeUnitAt(i) == Q_CODE) effectiveLen++;
    }
    return scoreLen(effectiveLen);
  }

  Boggle([int w = 5, int h = 5, String dice = null])
      : width = w,
        height = h,
        N = w * h,
        faces = new List<BoggleFace>(w * h) {
    //  create neighbors lookup tables
    for (int i = 0; i < N; i++) {
      var face = new BoggleFace();
      faces[i] = face;
      int x = i % w,
          y = i ~/ w;
      for (int j = 0; j < BoggleFace.NUM_NEIGHBORS; j++) {
        int cx = x + OFFX[j],
            cy = y + OFFY[j];
        if (0 <= cx &&
            cx < w &&
            0 <= cy &&
            cy < h) face.neighbors[j] = cx + cy * w;
      }
    }
    if (dice != null) letters = dice.toLowerCase();
  }

  //  Depth-first search inside trie/grid in parallel
  //  Callback is called on terminal nodes (full words)
  traverseBoard(trie, callback) {
    traversePath(BoggleFace face, TrieNode node, var path, var depth) {
      if (face.visited) return; // skip already visited faces
      var chNode = node.children[face.code];
      if (chNode == null) {
        //  prefix is not in the dictionary
        return;
      }
      //  the current prefix is in the dictionary
      if (chNode.terminal) {
        //  the prefix is also a full word
        callback(path, depth + 1, chNode);
      }
      //  go down, depth-first
      face.visited = true;
      for (int neighbor in face.neighbors) {
        if (neighbor != null) {
          path[depth + 1] = neighbor;
          traversePath(faces[neighbor], chNode, path, depth + 1);
        }
      }
      face.visited = false;
    }

    var path = new List<int>(N + 1);
    for (int i = 0; i < N; i++) {
      path[0] = i;
      traversePath(faces[i], trie, path, 0);
    }
  }

  //  returns list of all matching words from a trie dictionary
  List<String> getMatchingWords(TrieNode trie) {
    var res = [];
    traverseBoard(trie, (path, depth, node) {
      var cpath = path.take(depth).toList();
      res.add(cpath.map((i) => faces[i].char).join(''));
    });
    return res;
  }

  //  returns list of all possible paths for a word
  List<List<int>> getWordPaths(String word) {
    var trie = new TrieNode();
    trie.buildTrie([word]);
    var res = [];
    traverseBoard(trie, (path, depth, node) {
      res.add(path.take(depth).toList());
    });
    return res;
  }

  //  compute score for the board
  int getTotalScore(TrieNode trie, [bool computeScoreContrib = true]) {
    int res = 0;
    var visited = new Set<String>();
    traverseBoard(trie, (path, depth, node) {
      var word = path.take(depth).map((i) => faces[i].char).join('');
      if (!visited.contains(word)) {
        res += Boggle.scoreWord(word);
        visited.add(word);
      }
    });
    return res;
  }
}
