import 'dart:html';
import 'package:polymer/polymer.dart';

import 'trie.dart';
import 'boggle.dart';

const DEFAULT_LETTERS = 'SGECAAREMECGNTDOYSPJNOICD';
const DEFAULT_BOARD_W = 5;
const DEFAULT_BOARD_H = 5;
const DEFAULT_DICTIONARY = 'data/words.txt';
const END_PATH = 9;

class Face extends Object with Observable {
  final String letter;
  @observable int direction;  
  Face(this.letter, [this.direction=0]);
}

@CustomTag('main-app')
class MainApp extends PolymerElement {
  @observable List<String> words;
  @observable List<List<Face>> boards;
  @observable int score = 0;
  
  TrieNode trie;
  Boggle boggle;
  
  makeBoard() => boggle.letterList.map((s)=> new Face(s)).toList();
      
  set curWord(String word) {
    var w = (word == null) ? "" : word.trim().split('[')[0].replaceAll('qu', 'q');
    var paths = boggle.getWordPaths(w);
    if (paths.length == 0) {
      boards = [makeBoard()];
      return;
    }
    boards = [];
    for (var path in paths) {
      var board = makeBoard(); 
      final DIR_OFFS = Boggle.offsets(boggle.width);
      for (int i = 1; i < path.length; i++) {
        var pc = path[i];
        var pp = path[i - 1];
        board[pc].direction = DIR_OFFS.indexOf(pp - pc) + 1;  
      }
      board[path[0]].direction = END_PATH;
      boards.add(board);
    }
  }
    
  gatherMatchingWords() {
    var mw = boggle.getMatchingWords(trie);
    score = boggle.getTotalScore(trie);   
    var uw = {};
    for (var w in mw) {
      uw.putIfAbsent(w, () => 0);
      uw[w]++;
    }
    words = [];
    for (var w in uw.keys) {
      int nocc = uw[w];
      String qw = w.replaceAll('q', 'qu');
      words.add(nocc == 1 ? qw : "${qw}[${nocc}]"); 
    }
  }
  
  MainApp.created() : super.created()
  {
    var letters = Uri.base.queryParameters['letters'];
    if (letters == null) letters = DEFAULT_LETTERS;

    var dictionary = Uri.base.queryParameters['dictionary'];
    if (dictionary == null) dictionary = DEFAULT_DICTIONARY;

    var width = int.parse(Uri.base.queryParameters['width']);
    if (width == null) width = DEFAULT_BOARD_W;

    var height = int.parse(Uri.base.queryParameters['height']);
    if (height == null) height = DEFAULT_BOARD_H;
        
    //  load the dictionary
    HttpRequest.getString(dictionary).then((String dict) {
      boggle = new Boggle(width, height, letters);
      boards = [makeBoard()];
          
      trie = new TrieNode();
      trie.buildTrie(parseDictionary(dict));
      gatherMatchingWords();      
      curWord = Uri.base.queryParameters['word'];
    });
  }

  onHovered(MouseEvent event) => curWord = (event.target as Element).innerHtml;
  
  static List<String> parseDictionary(String dict, [bool skipImpossible = true]) {
    var re = new RegExp("q(?!u)|-|'|/");
    return dict
        .split(' ')
        .where((s) => !skipImpossible || !re.hasMatch(s))
        .map((s) => s.trim().toLowerCase().replaceAll('qu', 'q'))
        .toList()..sort();
  }
}
