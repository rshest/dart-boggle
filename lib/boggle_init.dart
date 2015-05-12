library boggle_init;

import 'dart:math';

import 'utils.dart';
import 'trie.dart';
import 'boggle.dart';

//  inits a board randomly, using probabilistic distributions from the trie
int initPrefix(Boggle boggle, Trie trie, List<Die> dice, int num, Random random,
    [int startCell = 0]) {
  if (num == null) num = boggle.N;

  int initRandomBranch(TrieNode node, int startCell) {
    var die = dice[startCell];
    int nDieFaces = die.faces.length;
    var prob = new List<int>(nDieFaces);
    int numValid = 0;
    for (int i = 0; i < nDieFaces; i++) {
      var d = die.faces[i];
      var p = node.children[d];
      if (p == null) {
        prob[i] = 0;
      } else {
        prob[i] = p.pathCount;
        assert(p.pathCount > 0);
        numValid++;
      }
    }
    if (numValid == 0) return -1;
    int charIdx = pickRandomW(random, prob, null);
    var char = die.faces[charIdx];
    var face = boggle.faces[startCell];
    face.code = char;
    face.visited = true;
    num--;

    //  depth-first recur into neighbors
    for (int neighbor in face.neighbors) {
      if (neighbor != null && !boggle.faces[neighbor].visited) {
        if (num <= 0) return neighbor;
        var cnode = node.children[char];
        assert(cnode != null);
        initRandomBranch(cnode, neighbor);
      }
    }
    return -1;
  }
  int res = -1;
  while (true) {
    res = initRandomBranch(trie.root, startCell);
    if (num <= 0) break;
    startCell = boggle.faces.indexOf(boggle.faces.firstWhere((f) => !f.visited));
  }
  boggle.faces.forEach((f) => f.visited = false);
  return res;
}

initGreedy(Boggle boggle, Trie trie, List<Die> dice, int num, Random random,
    [int startCell = 0]) {
  if (num == null) num = boggle.N;

  initRandomBranch(int startCell) {
    var face = boggle.faces[startCell];
    var die = dice[startCell];
    int nDieFaces = die.faces.length;
    int bestScore = 0;
    int bestFace = random.nextInt(nDieFaces);
    for (int i = 0; i < nDieFaces; i++) {
      face.code = die.faces[i];
      int score = boggle.getTotalScore(trie);
      if (score > bestScore) {
        bestScore = score;
        bestFace = i;
      }
    }
    face.code = die.faces[bestFace];

    num--;
    if (num == 0) return;

    //  depth-first recur into neighbors
    for (int neighbor in face.neighbors) {
      if (neighbor != null && !boggle.faces[neighbor].visited) {
        initRandomBranch(neighbor);
        if (num == 0) return;
      }
    }
  }
  initRandomBranch(startCell);
  boggle.faces.forEach((f) => f.visited = false);
}