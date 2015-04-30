library boggle;
import 'dart:math';
import 'dawg.dart';

const DEFAULT_DICE = 'SGECAAREMECGNTDOYSPJNOICD';

class _Face {
  static const NUM_NEIGHBORS = 8;
  final neighbors = new List<int>(NUM_NEIGHBORS); // clockwise, from top
  int code;
  bool visited = false;
  
  get char => new String.fromCharCode(code);
  set char(String s) => code = s.codeUnitAt(0);
}

class Boggle {
  final width, height, N;
  final List<_Face> faces;
  
  static const OFFX = const [0, 1, 1, 1, 0, -1, -1, -1];
  static const OFFY = const [-1, -1, 0, 1, 1, 1, 0, -1];   
  static offsets(int w) =>
    [-w, -w + 1, 1, w + 1, w, w - 1, -1, -w - 1];
  
  get letterList => faces.map((f) => f.char.toUpperCase());
  
  set letters(String s) {
    assert(s.length == N);
    for (int i = 0; i < N; i++) faces[i].char = s[i];
  } 
  
  static int rate(int n) => [0, 1, 2, 3, 5, 11][max(0, min(5, n - 3))];
  
  Boggle([String dice = null, w = 5, h = 5]) :
    width = w, height = h, N = w*h, 
    faces = new List<_Face>(w*h)
  {
    //  create neighbors
    final off = offsets(w);
    for (int i = 0; i < N; i++) {
      var face = new _Face();
      faces[i] = face;
      int x = i % w, y = i ~/ w;
      for (int j = 0; j < _Face.NUM_NEIGHBORS; j++) {
        int cx = x + OFFX[j], cy = y + OFFY[j];
        if (0 <= cx && cx < w && 0 <= cy && cy < h) 
          face.neighbors[j] = cx + cy*w;
      }
    }
    if (dice == null) dice = DEFAULT_DICE;
    letters = dice.toLowerCase();
  }
    
  collectMatches(_Face face, DawgNode node, var path, var depth, wordCallback) {
    if (face.visited) return; // skip already visited faces
    var chNode = node.children[face.code];
    if (chNode == null) {
      //  prefix is not in the dictionary
      return; 
    }
    //  the current prefix is in the dictionary
    if (chNode.terminal) {
      //  the prefix is also a full word
      wordCallback(path, depth + 1);
    }
    //  go down, depth-first
    face.visited = true;
    for (int neighbor in face.neighbors) {
      if (neighbor != null) {
        path[depth + 1] = neighbor;
        collectMatches(faces[neighbor], chNode, path, depth + 1, wordCallback);
      }
    }
    face.visited = false;
  }
  
  traverseBoard(dawg, callback) {
    //  Depth-first search inside DAWG/grid in parallel
    var path = new List<int>(N + 1);
    for (int i = 0; i < N; i++) {
      path[0] = i;
      collectMatches(faces[i], dawg.root, path, 0, callback);
    }
  }
  
  List<String> getMatchingWords(Dawg dawg) {
    var res = [];
    traverseBoard(dawg, (path, depth) {
      var cpath = path.take(depth).toList();
      res.add(cpath.map((i)=>faces[i].char).join(''));
    });
    return res;
  }

  List<List<int>> getWordPaths(String word) {
    var dawg = new Dawg([word]);
    var res = [];
    traverseBoard(dawg, (path, depth) {
      res.add(path.take(depth).toList());
    });
    return res;
  }
  
  int getTotalScore(Dawg dawg) {
    int res = 0;
    traverseBoard(dawg, (path, depth) {
      res += Boggle.rate(depth);
    });
    return res;
  }
}
