import 'dart:io';
import 'boggle.dart';
import 'grinder.dart';

void main(List<String> arguments)  {  
  String seed = "PointsPLZ?!!";
  if (arguments.length > 0) seed = arguments[0];
  print("Grinding with the seed: ${seed}");

  String readFile(path) => (new File(path)).readAsStringSync();
  var dice = Boggle.parseDice(readFile("./web/data/dice.txt"));
  var trie = new Trie(Trie.parseDictionary(readFile("./web/data/words.txt")));
  var grinder = new Grinder(dice, trie);
  grinder.grind(seed);
}