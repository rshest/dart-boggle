library markov;

import 'dart:math';
import "utils.dart";

class MarkovChain {
  final _transitions = new Map<int, Map<int, int>>();

  void addWord(String word, [bool terminate = false]) {
    int nch = word.length;
    if (nch == 0) return;
    int prevCh = 0;
    int endCh = terminate ? nch : nch - 1;
    for (int i = 0; i <= endCh; i++) {
      int curCh = i < nch ? word.codeUnitAt(i) : 0;
      var t = _transitions.putIfAbsent(prevCh, () => new Map<int, int>());
      var t1 = t.putIfAbsent(curCh, () => 0);
      t1++;
      t[curCh] = t1;
      prevCh = curCh;
    }
  }

  int pickNext(int current, Random random) {
    var t = _transitions[current];
    if (t == null) return 0;
    int idx = pickRandomW(random, t.values);
    return t.keys.toList()[idx];
  }

  String makeRandomWord(Random random, [int maxLen = 10]) {
    int prevCh = 0;
    var chars = [];
    for (int i = 0; i < maxLen; i++) {
      int ch = pickNext(prevCh, random);
      if (ch == 0) break;
      chars.add(ch);
      prevCh = ch;
    }
    var sb = new StringBuffer();
    chars.forEach((c) => sb.writeCharCode(c));
    return sb.toString();
  }

  printGraph() {
    for (var c in _transitions.keys) {
      var sb = new StringBuffer();
      sb.writeCharCode(c);
      sb.write("[ ");
      var tc = _transitions[c];
      for (var t in tc.keys) {
        sb.writeCharCode(t);
        sb.write(tc[t].toString());
        sb.write(" ");
      }
      sb.write("]");
      print(sb.toString());
    }
  }
}