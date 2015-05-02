import 'dart:io';
import 'dawg.dart';
import 'boggle.dart';
import 'grinder.dart';

void main(List<String> arguments)  {  
  String seed = "PointsPLZ?!!";
  if (arguments.length > 0) seed = arguments[0];
  print("Grinding with the seed: ${seed}");

  String readFile(path) => (new File(path)).readAsStringSync();
  var dice = Boggle.parseDice(readFile("./web/data/dice.txt"));
  var dawg = new Dawg(Dawg.parseDictionary(readFile("./web/data/words.txt")));
  var grinder = new Grinder(dice, dawg);
  grinder.grind(seed);
}