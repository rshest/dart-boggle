import 'dart:io';
import 'dart:math';

import 'trie.dart';
import 'boggle.dart';
import 'grinder.dart';
import 'markov.dart';

void main(List<String> arguments)  {
  String seed = "PointsPLZ?!!";
  if (arguments.length > 0) seed = arguments[0];
  print("Grinding with the seed: ${seed}");

  String readFile(path) => (new File(path)).readAsStringSync();
  var dice = Boggle.parseDice(readFile("./web/data/dice.txt"));
  var dict = Trie.parseDictionary(readFile("./web/data/words.txt"));
  var trie = new Trie(dict, Boggle.scoreWord);
  var grinder = new Grinder(dice, trie);

  int totalScore = 0;
  for (var w in dict) {
    totalScore += Boggle.scoreWord(w);
  }

  var fullDict = Trie.parseDictionary(readFile("./web/data/words.txt"), false);
  print("totalScore: ${totalScore}, words: ${dict.length}, fullWords:${fullDict.length}");

  grinder.grind(seed.hashCode);

  var mc = new MarkovChain();
  for (var word in dict) {
    mc.addWord(word);
  }

  mc.printGraph();


  var rnd = new Random(123);
  for (int i = 0; i < 1000; i++) {
    int len = rnd.nextInt(10) + 4;
    print(mc.makeRandomWord(rnd, len));
  }

  dict.sort((a, b) => a.length - b.length);
  dict.forEach((s)=>print(s));

}