import 'dart:io';
import 'dawg.dart';
import 'boggle.dart';
import 'grinder.dart';

String readFile(path) => (new File(path)).readAsStringSync();

String seed0 = "aefeamaixcclshlloetefvrno";
String stealSteady = "sigerftrnttyealqidttewnes";
String lastLaser = "lrtsltasiaretnocaeicnavkn";
String strangeStrain = "rpotedilsatnaethtgrnkiehe"; // 226
String flatFace = "fledoeacmgsrtofaeoinepenb"; // 208
String the201 = "httnjfeggyoranentelttsept"; // 201

void main(List<String> arguments)  {  
  String seed = Boggle.DEFAULT_DICE;
  if (arguments.length > 0) seed = arguments[0];
  seed = seed.toUpperCase();
  print("Grinding with the seed: ${seed}");
  
  String dict = readFile("./web/data/words.txt");
  var dawg = new Dawg(Dawg.parseDictionary(dict));
  
  var dice = Grinder.parseDice(readFile("./web/data/dice.txt"));
  var grinder = new Grinder(dice, dawg);
  print((new Boggle(seed)).getNonRepeatScore(dawg));
  grinder.grind("ok see you tomorrow");
}